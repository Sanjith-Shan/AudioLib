import Foundation

final class ProgressiveDownloadManager: NSObject, URLSessionDataDelegate {

    static let firstChunkSize: Int64 = 8 * 1024 * 1024
    static let totalChunks = 16
    // When chunk 0 reaches this many bytes, flag streaming as ready.
    static let streamingReadyThreshold: Int64 = 1 * 1024 * 1024

    let bookID: UUID
    let outputURL: URL
    let totalBytes: Int64

    var onStreamingReady: (() -> Void)?
    var onProgress: ((Double, Double, Int64, Int64) -> Void)?
    var onComplete: (() -> Void)?
    var onFailed: ((Error) -> Void)?
    var onChunkWritten: (() -> Void)?

    private let url: URL
    private let headers: [String: String]

    private let lock = NSLock()
    private var writtenRanges: [ClosedRange<Int64>] = []
    private var chunkBytesWritten: [Int: Int64] = [:]
    private var chunkExpectedSize: [Int: Int64] = [:]
    private var chunkRangeStart: [Int: Int64] = [:]
    private var speedWindow: [(TimeInterval, Int64)] = []
    private var streamingDidFire = false
    private var completionDidFire = false
    private var failureDidFire = false
    private var activeTasks: [URLSessionDataTask] = []
    private var taskToChunk: [Int: (index: Int, offset: Int64)] = [:]
    private var taskHandles: [Int: FileHandle] = [:]
    private var chunkCount: Int = 0

    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.default
        cfg.httpMaximumConnectionsPerHost = 16
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 43200
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()

    init(bookID: UUID, url: URL, headers: [String: String], totalBytes: Int64, outputURL: URL) {
        self.bookID = bookID
        self.url = url
        self.headers = headers
        self.totalBytes = totalBytes
        self.outputURL = outputURL
        super.init()
    }

    func start() {
        let fm = FileManager.default
        if fm.fileExists(atPath: outputURL.path) {
            try? fm.removeItem(at: outputURL)
        }
        fm.createFile(atPath: outputURL.path, contents: nil)
        if totalBytes > 0 {
            if let handle = try? FileHandle(forWritingTo: outputURL) {
                try? handle.truncate(atOffset: UInt64(totalBytes))
                try? handle.close()
            }
        }

        let ranges = computeChunkRanges()
        chunkCount = ranges.count

        lock.lock()
        for (i, range) in ranges.enumerated() {
            chunkBytesWritten[i] = 0
            chunkRangeStart[i] = range.start
            if let end = range.end {
                chunkExpectedSize[i] = end - range.start + 1
            }
        }
        lock.unlock()

        for (i, range) in ranges.enumerated() {
            downloadChunk(index: i, range: range)
        }
    }

    func cancel() {
        lock.lock()
        let tasks = activeTasks
        activeTasks.removeAll()
        let handles = Array(taskHandles.values)
        taskHandles.removeAll()
        taskToChunk.removeAll()
        lock.unlock()
        tasks.forEach { $0.cancel() }
        handles.forEach { try? $0.close() }
    }

    func availableRanges() -> [ClosedRange<Int64>] {
        lock.lock()
        defer { lock.unlock() }
        return writtenRanges
    }

    func isAvailable(from start: Int64, length: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        let end = start + Int64(length) - 1
        return writtenRanges.contains { $0.lowerBound <= start && $0.upperBound >= end }
    }

    func readData(offset: Int64, length: Int) -> Data? {
        guard isAvailable(from: offset, length: length) else { return nil }
        guard let handle = try? FileHandle(forReadingFrom: outputURL) else { return nil }
        defer { try? handle.close() }
        do {
            try handle.seek(toOffset: UInt64(offset))
        } catch {
            return nil
        }
        return handle.readData(ofLength: length)
    }

    // MARK: - Chunk planning

    private func computeChunkRanges() -> [(start: Int64, end: Int64?)] {
        if totalBytes <= 0 {
            return [(0, nil)]
        }
        if totalBytes <= Self.firstChunkSize {
            return [(0, totalBytes - 1)]
        }

        var ranges: [(start: Int64, end: Int64?)] = []
        ranges.append((0, min(Self.firstChunkSize - 1, totalBytes - 1)))

        let remainingBytes = totalBytes - Self.firstChunkSize
        let remainingChunks = Int64(Self.totalChunks - 1)
        let perChunk = (remainingBytes + remainingChunks - 1) / remainingChunks

        var start = Self.firstChunkSize
        while start < totalBytes {
            let end = min(start + perChunk - 1, totalBytes - 1)
            ranges.append((start, end))
            start = end + 1
        }
        return ranges
    }

    // MARK: - Chunk downloading (delegate-based streaming)

    private func downloadChunk(index: Int, range: (start: Int64, end: Int64?)) {
        let rangedURL = urlWithRangeParam(url, start: range.start, end: range.end)
        var req = URLRequest(url: rangedURL)
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        if let end = range.end {
            req.setValue("bytes=\(range.start)-\(end)", forHTTPHeaderField: "Range")
        } else {
            req.setValue("bytes=\(range.start)-", forHTTPHeaderField: "Range")
        }

        let handle: FileHandle
        do {
            handle = try FileHandle(forWritingTo: outputURL)
            try handle.seek(toOffset: UInt64(range.start))
        } catch {
            reportFailure(error)
            return
        }

        let task = session.dataTask(with: req)

        lock.lock()
        activeTasks.append(task)
        taskToChunk[task.taskIdentifier] = (index: index, offset: range.start)
        taskHandles[task.taskIdentifier] = handle
        lock.unlock()

        task.resume()
    }

    // MARK: - URLSessionDataDelegate

    func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping (URLSession.ResponseDisposition) -> Void
    ) {
        guard let http = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        if http.statusCode == 200 || http.statusCode == 206 {
            completionHandler(.allow)
        } else {
            completionHandler(.cancel)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        guard let mapping = taskToChunk[dataTask.taskIdentifier],
              let handle = taskHandles[dataTask.taskIdentifier] else {
            lock.unlock()
            return
        }

        // Write bytes at the current end of this chunk. The handle was seeked
        // to the chunk's start at task creation and is written sequentially.
        handle.write(data)
        let newBytes = Int64(data.count)
        chunkBytesWritten[mapping.index] = (chunkBytesWritten[mapping.index] ?? 0) + newBytes

        let sumWritten = chunkBytesWritten.values.reduce(0, +)
        let totalForFraction = totalBytes > 0 ? totalBytes : sumWritten

        let now = Date().timeIntervalSince1970
        speedWindow.append((now, sumWritten))
        let cutoff = now - 2.0
        while speedWindow.count > 1, speedWindow.first!.0 < cutoff {
            speedWindow.removeFirst()
        }

        var bytesPerSec: Double = 0
        if let first = speedWindow.first, speedWindow.count > 1 {
            let dt = now - first.0
            let db = sumWritten - first.1
            if dt > 0 { bytesPerSec = Double(db) / dt }
        }

        let fraction = totalForFraction > 0 ? min(1.0, Double(sumWritten) / Double(totalForFraction)) : 0

        // Streaming-ready heuristic: chunk 0 has enough data to start playing.
        let chunk0Bytes = chunkBytesWritten[0] ?? 0
        let chunk0Threshold: Int64 = {
            if totalBytes > 0 {
                return min(Self.streamingReadyThreshold, totalBytes)
            }
            return Self.streamingReadyThreshold
        }()
        let shouldFireStreaming = (mapping.index == 0)
            && !streamingDidFire
            && chunk0Bytes >= chunk0Threshold
        if shouldFireStreaming { streamingDidFire = true }
        lock.unlock()

        let onProgressCb = onProgress
        let onChunkWrittenCb = onChunkWritten
        let onStreamingCb = onStreamingReady

        DispatchQueue.main.async {
            onProgressCb?(fraction, bytesPerSec, sumWritten, totalForFraction)
            onChunkWrittenCb?()
            if shouldFireStreaming { onStreamingCb?() }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        let mapping = taskToChunk[task.taskIdentifier]
        let handle = taskHandles[task.taskIdentifier]
        taskHandles.removeValue(forKey: task.taskIdentifier)
        taskToChunk.removeValue(forKey: task.taskIdentifier)
        if let t = task as? URLSessionDataTask,
           let idx = activeTasks.firstIndex(where: { $0 === t }) {
            activeTasks.remove(at: idx)
        }
        lock.unlock()

        try? handle?.close()

        if let error = error, (error as NSError).code != NSURLErrorCancelled {
            reportFailure(error)
            return
        }

        if error != nil { return } // cancelled, do nothing

        guard let mapping else { return }

        // Chunk completed — mark its range as fully written.
        lock.lock()
        let written = chunkBytesWritten[mapping.index] ?? 0
        if written > 0 {
            let start = mapping.offset
            let newRange = start...(start + written - 1)
            mergeRanges(adding: newRange)
        }

        let allDone = checkAllDone_locked()
        let shouldCompleteNow = allDone && !completionDidFire
        if shouldCompleteNow { completionDidFire = true }
        lock.unlock()

        let onChunkWrittenCb = onChunkWritten
        let onCompleteCb = onComplete

        DispatchQueue.main.async {
            onChunkWrittenCb?()
            if shouldCompleteNow { onCompleteCb?() }
        }
    }

    // MARK: - Private helpers

    private func mergeRanges(adding newRange: ClosedRange<Int64>) {
        var merged: [ClosedRange<Int64>] = []
        var current = newRange
        let all = (writtenRanges + [newRange]).sorted { $0.lowerBound < $1.lowerBound }
        var first = true
        for r in all {
            if first {
                current = r
                first = false
                continue
            }
            if r.lowerBound <= current.upperBound + 1 {
                current = current.lowerBound...max(current.upperBound, r.upperBound)
            } else {
                merged.append(current)
                current = r
            }
        }
        if !first { merged.append(current) }
        writtenRanges = merged
    }

    private func checkAllDone_locked() -> Bool {
        if totalBytes <= 0 {
            // Unknown length: rely on single chunk completing
            return (chunkBytesWritten[0] ?? 0) > 0 && taskToChunk.isEmpty
        }
        let sum = chunkBytesWritten.values.reduce(0, +)
        return sum >= totalBytes
    }

    private func reportFailure(_ error: Error) {
        lock.lock()
        if failureDidFire { lock.unlock(); return }
        failureDidFire = true
        let tasks = activeTasks
        activeTasks.removeAll()
        let handles = Array(taskHandles.values)
        taskHandles.removeAll()
        taskToChunk.removeAll()
        lock.unlock()
        tasks.forEach { $0.cancel() }
        handles.forEach { try? $0.close() }

        let cb = onFailed
        DispatchQueue.main.async { cb?(error) }
    }

    private func urlWithRangeParam(_ base: URL, start: Int64, end: Int64?) -> URL {
        let rangeStr = end.map { "\(start)-\($0)" } ?? "\(start)-"
        guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return base }
        var items = comps.queryItems ?? []
        items.removeAll { $0.name == "range" }
        items.append(URLQueryItem(name: "range", value: rangeStr))
        comps.queryItems = items
        return comps.url ?? base
    }
}
