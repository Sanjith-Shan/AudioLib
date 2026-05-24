import Foundation

final class BackgroundDownloadSession: NSObject, URLSessionDownloadDelegate {

    static let shared = BackgroundDownloadSession()
    static let sessionID = "com.sanjith.audiolib.bg.v2"

    var onBookFinished: ((String, URL) -> Void)?
    // (bookID, fraction 0-1, bytesPerSec, bytesDownloaded, bytesTotal)
    var onProgress: ((String, Double, Double, Int64, Int64) -> Void)?
    var onBookNeedsReResolve: ((String) -> Void)?
    var onBookFailed: ((String, Error) -> Void)?

    private var bgCompletionHandler: (() -> Void)?
    private let lock = NSLock()

    // Aggregate bytes-written tracking for speed/ETA per book
    private var chunkBytesWritten: [String: [Int: Int64]] = [:]
    private var chunkBytesTotal:   [String: [Int: Int64]] = [:]
    private var speedWindow:       [String: [(TimeInterval, Int64)]] = [:]
    private var chunkRetries:      [String: [Int: Int]] = [:]

    private(set) lazy var session: URLSession = {
        let config = URLSessionConfiguration.background(withIdentifier: Self.sessionID)
        config.isDiscretionary = false
        #if os(iOS)
        config.sessionSendsLaunchEvents = true
        #endif
        config.httpMaximumConnectionsPerHost = 16
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 43200
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    struct ChunkRecord: Codable {
        let bookID: String
        let streamURL: String
        let headers: [String: String]
        let fileExtension: String
        var chunks: [ChunkInfo]
        let resolvedAt: TimeInterval

        struct ChunkInfo: Codable {
            let index: Int
            let rangeStart: Int64
            let rangeEnd: Int64?
            var taskID: Int
            var isDone: Bool
            var localFilename: String
        }
    }

    // MARK: - Paths

    private static var chunkStateDir: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("chunkState", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private static func recordURL(for bookID: String) -> URL {
        chunkStateDir.appendingPathComponent("\(bookID).json")
    }

    private static func chunkFileURL(bookID: String, index: Int) -> URL {
        chunkStateDir.appendingPathComponent("\(bookID)_chunk_\(index).tmp")
    }

    // MARK: - Public API

    func startDownload(
        bookID: String,
        streamURL: URL,
        headers: [String: String],
        fileExtension: String,
        chunkCount: Int = 8
    ) async throws {
        let totalSize = await fetchContentLength(url: streamURL, headers: headers)

        var chunks: [ChunkRecord.ChunkInfo] = []
        if totalSize > 0 {
            let size = (totalSize + Int64(chunkCount) - 1) / Int64(chunkCount)
            var start: Int64 = 0
            var idx = 0
            while start < totalSize {
                let end = min(start + size - 1, totalSize - 1)
                chunks.append(ChunkRecord.ChunkInfo(
                    index: idx,
                    rangeStart: start,
                    rangeEnd: end,
                    taskID: 0,
                    isDone: false,
                    localFilename: "\(bookID)_chunk_\(idx).tmp"
                ))
                start = end + 1
                idx += 1
            }
        } else {
            chunks.append(ChunkRecord.ChunkInfo(
                index: 0,
                rangeStart: 0,
                rangeEnd: nil,
                taskID: 0,
                isDone: false,
                localFilename: "\(bookID)_chunk_0.tmp"
            ))
        }

        var record = ChunkRecord(
            bookID: bookID,
            streamURL: streamURL.absoluteString,
            headers: headers,
            fileExtension: fileExtension,
            chunks: chunks,
            resolvedAt: Date().timeIntervalSince1970
        )

        lock.withLock {
            chunkBytesWritten[bookID] = [:]
            chunkBytesTotal[bookID] = [:]
            speedWindow[bookID] = []
            chunkRetries[bookID] = [:]
            for chunk in chunks {
                if let end = chunk.rangeEnd {
                    chunkBytesTotal[bookID]?[chunk.index] = end - chunk.rangeStart + 1
                }
                chunkBytesWritten[bookID]?[chunk.index] = 0
            }
        }

        for i in 0..<record.chunks.count {
            let taskID = launchChunkTask(
                bookID: bookID,
                chunk: record.chunks[i],
                streamURL: streamURL,
                headers: headers
            )
            record.chunks[i].taskID = taskID
        }

        saveChunkRecord(record, for: bookID)
    }

    func cancel(bookID: String) {
        guard let record = loadChunkRecord(for: bookID) else {
            cleanupBook(bookID: bookID)
            return
        }
        let taskIDs = Set(record.chunks.map { $0.taskID })
        session.getAllTasks { tasks in
            for t in tasks where taskIDs.contains(t.taskIdentifier) {
                t.cancel()
            }
        }
        cleanupBook(bookID: bookID)
    }

    func handleEventsForBackgroundURLSession(_ completionHandler: @escaping () -> Void) {
        bgCompletionHandler = completionHandler
        _ = session
    }

    func reconnectExistingDownloads() {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(
            at: Self.chunkStateDir,
            includingPropertiesForKeys: nil
        ) else { return }

        let records = files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> ChunkRecord? in
                guard let data = try? Data(contentsOf: url),
                      let rec = try? JSONDecoder().decode(ChunkRecord.self, from: data) else { return nil }
                return rec
            }

        for record in records {
            lock.withLock {
                chunkBytesWritten[record.bookID] = [:]
                chunkBytesTotal[record.bookID] = [:]
                speedWindow[record.bookID] = []
                chunkRetries[record.bookID] = [:]
                for chunk in record.chunks {
                    if let end = chunk.rangeEnd {
                        chunkBytesTotal[record.bookID]?[chunk.index] = end - chunk.rangeStart + 1
                    }
                    chunkBytesWritten[record.bookID]?[chunk.index] = chunk.isDone ? (chunkBytesTotal[record.bookID]?[chunk.index] ?? 0) : 0
                }
            }
        }

        session.getAllTasks { [weak self] tasks in
            guard let self else { return }
            let liveIDs = Set(tasks.map { $0.taskIdentifier })
            for var record in records {
                var dirty = false
                for i in 0..<record.chunks.count {
                    let chunk = record.chunks[i]
                    if chunk.isDone { continue }
                    if liveIDs.contains(chunk.taskID) { continue }
                    guard let url = URL(string: record.streamURL) else { continue }
                    let newID = self.launchChunkTask(
                        bookID: record.bookID,
                        chunk: chunk,
                        streamURL: url,
                        headers: record.headers
                    )
                    record.chunks[i].taskID = newID
                    dirty = true
                }
                if dirty {
                    self.saveChunkRecord(record, for: record.bookID)
                }
            }
        }
    }

    // MARK: - Private helpers

    @discardableResult
    private func launchChunkTask(
        bookID: String,
        chunk: ChunkRecord.ChunkInfo,
        streamURL: URL,
        headers: [String: String]
    ) -> Int {
        // YouTube's CDN throttles HTTP Range-header-only requests at ~200 KB/s.
        // Appending a `range=` query parameter bypasses throttling.
        let rangedURL = Self.urlWithRangeParam(streamURL, start: chunk.rangeStart, end: chunk.rangeEnd)
        var req = URLRequest(url: rangedURL)
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        if let end = chunk.rangeEnd {
            req.setValue("bytes=\(chunk.rangeStart)-\(end)", forHTTPHeaderField: "Range")
        } else {
            req.setValue("bytes=\(chunk.rangeStart)-", forHTTPHeaderField: "Range")
        }
        let task = session.downloadTask(with: req)
        // taskDescription encodes the book+chunk owner so delegate callbacks can recover it
        // without loading the on-disk record on every invocation.
        task.taskDescription = "\(bookID)|\(chunk.index)"
        task.resume()
        return task.taskIdentifier
    }

    static func urlWithRangeParam(_ base: URL, start: Int64, end: Int64?) -> URL {
        let rangeStr = end.map { "\(start)-\($0)" } ?? "\(start)-"
        guard var comps = URLComponents(url: base, resolvingAgainstBaseURL: false) else { return base }
        var items = comps.queryItems ?? []
        items.removeAll { $0.name == "range" }
        items.append(URLQueryItem(name: "range", value: rangeStr))
        comps.queryItems = items
        return comps.url ?? base
    }

    private func saveChunkRecord(_ record: ChunkRecord, for bookID: String) {
        guard let data = try? JSONEncoder().encode(record) else { return }
        let url = Self.recordURL(for: bookID)
        try? data.write(to: url, options: .atomic)
    }

    private func loadChunkRecord(for bookID: String) -> ChunkRecord? {
        let url = Self.recordURL(for: bookID)
        guard let data = try? Data(contentsOf: url),
              let record = try? JSONDecoder().decode(ChunkRecord.self, from: data) else { return nil }
        return record
    }

    private func cleanupBook(bookID: String) {
        let fm = FileManager.default
        if let record = loadChunkRecord(for: bookID) {
            for chunk in record.chunks {
                try? fm.removeItem(at: Self.chunkFileURL(bookID: bookID, index: chunk.index))
            }
        }
        try? fm.removeItem(at: Self.recordURL(for: bookID))
        if let files = try? fm.contentsOfDirectory(at: Self.chunkStateDir, includingPropertiesForKeys: nil) {
            for file in files where file.lastPathComponent.hasPrefix("\(bookID)_chunk_") {
                try? fm.removeItem(at: file)
            }
        }
        lock.lock()
        chunkBytesWritten.removeValue(forKey: bookID)
        chunkBytesTotal.removeValue(forKey: bookID)
        speedWindow.removeValue(forKey: bookID)
        chunkRetries.removeValue(forKey: bookID)
        lock.unlock()
    }

    private func ownerFor(task: URLSessionTask) -> (bookID: String, chunkIndex: Int)? {
        if let desc = task.taskDescription {
            let parts = desc.split(separator: "|", maxSplits: 1)
            if parts.count == 2, let idx = Int(parts[1]) {
                return (String(parts[0]), idx)
            }
        }
        let taskID = task.taskIdentifier
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(at: Self.chunkStateDir, includingPropertiesForKeys: nil) else { return nil }
        for file in files where file.pathExtension == "json" {
            guard let data = try? Data(contentsOf: file),
                  let record = try? JSONDecoder().decode(ChunkRecord.self, from: data) else { continue }
            if let chunk = record.chunks.first(where: { $0.taskID == taskID }) {
                return (record.bookID, chunk.index)
            }
        }
        return nil
    }

    private func fetchContentLength(url: URL, headers: [String: String]) async -> Int64 {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        for (k, v) in headers { req.setValue(v, forHTTPHeaderField: k) }
        guard let (_, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse else { return 0 }
        let raw = http.allHeaderFields["Content-Length"] ?? http.allHeaderFields["content-length"]
        if let s = raw as? String, let n = Int64(s) { return n }
        if let n = raw as? NSNumber { return n.int64Value }
        return 0
    }

    private func assembleAndFinish(bookID: String, record: ChunkRecord) {
        let fm = FileManager.default
        let output = fm.temporaryDirectory.appendingPathComponent("\(bookID)_assembled.\(record.fileExtension)")

        do {
            if fm.fileExists(atPath: output.path) {
                try fm.removeItem(at: output)
            }
            fm.createFile(atPath: output.path, contents: nil)
            let outHandle = try FileHandle(forWritingTo: output)
            defer { try? outHandle.close() }

            let sorted = record.chunks.sorted { $0.index < $1.index }
            for chunk in sorted {
                let src = Self.chunkFileURL(bookID: bookID, index: chunk.index)
                let inHandle = try FileHandle(forReadingFrom: src)
                while true {
                    let data = inHandle.readData(ofLength: 1_048_576)
                    if data.isEmpty { break }
                    outHandle.write(data)
                }
                try? inHandle.close()
            }

            let cb = onBookFinished
            DispatchQueue.main.async { cb?(bookID, output) }

            cleanupBook(bookID: bookID)
        } catch {
            let cb = onBookFailed
            DispatchQueue.main.async { cb?(bookID, error) }
        }
    }

    // MARK: - URLSessionDownloadDelegate

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let owner = ownerFor(task: downloadTask) else { return }
        let bookID = owner.bookID
        let chunkIndex = owner.chunkIndex

        let dest = Self.chunkFileURL(bookID: bookID, index: chunkIndex)
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.moveItem(at: location, to: dest)
        } catch {
            let cb = onBookFailed
            DispatchQueue.main.async { cb?(bookID, error) }
            return
        }

        guard var record = loadChunkRecord(for: bookID) else { return }
        if let i = record.chunks.firstIndex(where: { $0.index == chunkIndex }) {
            record.chunks[i].isDone = true
        }
        saveChunkRecord(record, for: bookID)

        lock.lock()
        if let total = chunkBytesTotal[bookID]?[chunkIndex] {
            chunkBytesWritten[bookID]?[chunkIndex] = total
        }
        lock.unlock()

        let allDone = record.chunks.allSatisfy { $0.isDone }
        if allDone {
            assembleAndFinish(bookID: bookID, record: record)
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let owner = ownerFor(task: downloadTask) else { return }
        let bookID = owner.bookID
        let chunkIndex = owner.chunkIndex

        lock.lock()
        chunkBytesWritten[bookID]?[chunkIndex] = totalBytesWritten
        if totalBytesExpectedToWrite > 0 {
            chunkBytesTotal[bookID]?[chunkIndex] = totalBytesExpectedToWrite
        }
        let writtenDict = chunkBytesWritten[bookID] ?? [:]
        let totalDict = chunkBytesTotal[bookID] ?? [:]
        let sumWritten = writtenDict.values.reduce(0, +)
        let sumTotal = totalDict.values.reduce(0, +)

        let now = Date().timeIntervalSince1970
        var window = speedWindow[bookID] ?? []
        window.append((now, sumWritten))
        let cutoff = now - 2.0
        while window.count > 1, window.first!.0 < cutoff {
            window.removeFirst()
        }
        speedWindow[bookID] = window

        var bytesPerSec: Double = 0
        if let first = window.first, window.count > 1 {
            let dt = now - first.0
            let db = sumWritten - first.1
            if dt > 0 { bytesPerSec = Double(db) / dt }
        }
        lock.unlock()

        let fraction = sumTotal > 0 ? min(1.0, Double(sumWritten) / Double(sumTotal)) : 0
        let cb = onProgress
        DispatchQueue.main.async {
            cb?(bookID, fraction, bytesPerSec, sumWritten, sumTotal)
        }
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error = error else { return }
        guard let owner = ownerFor(task: task) else { return }
        let bookID = owner.bookID
        let chunkIndex = owner.chunkIndex

        if (error as NSError).code == NSURLErrorCancelled { return }

        guard let record = loadChunkRecord(for: bookID) else { return }

        let expired = Date().timeIntervalSince1970 - record.resolvedAt > 5 * 3600
        let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        let isAuthError = statusCode == 403 || statusCode == 410

        if expired || isAuthError {
            let cb = onBookNeedsReResolve
            DispatchQueue.main.async { cb?(bookID) }
            return
        }

        lock.lock()
        let retries = (chunkRetries[bookID]?[chunkIndex] ?? 0) + 1
        chunkRetries[bookID]?[chunkIndex] = retries
        lock.unlock()

        if retries > 3 {
            let cb = onBookFailed
            DispatchQueue.main.async { cb?(bookID, error) }
            return
        }

        let delay = pow(2.0, Double(retries - 1))
        let chunk = record.chunks.first(where: { $0.index == chunkIndex })
        guard let chunk, let url = URL(string: record.streamURL) else { return }
        let headers = record.headers
        let bookIDCopy = bookID
        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            let newID = self.launchChunkTask(bookID: bookIDCopy, chunk: chunk, streamURL: url, headers: headers)
            guard var r = self.loadChunkRecord(for: bookIDCopy) else { return }
            if let i = r.chunks.firstIndex(where: { $0.index == chunkIndex }) {
                r.chunks[i].taskID = newID
            }
            self.saveChunkRecord(r, for: bookIDCopy)
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            self?.bgCompletionHandler?()
            self?.bgCompletionHandler = nil
        }
    }
}
