import Foundation

// Parallel chunked downloader.
// Issues N concurrent Range-header data tasks, streams each chunk to a temp
// FileHandle without buffering in RAM, then concatenates to the output path.
// Thread-safety: all mutable state protected by `lock`; delegate callbacks
// run on the URLSession delegate queue (background).
final class ChunkedDownloader: NSObject, URLSessionDataDelegate {

    // Called on main thread with aggregate [0, 1] progress.
    var onProgress: (@MainActor (Double) -> Void)?

    private let url: URL
    private let headers: [String: String]
    private let chunkCount: Int
    private let maxRetries: Int

    private var session: URLSession!

    private let lock = NSLock()
    private var taskToChunk  = [Int: Int]()
    private var chunkFiles   = [Int: URL]()
    private var chunkHandles = [Int: FileHandle]()
    private var chunkWritten = [Int: Int64]()
    private var chunkTotal   = [Int: Int64]()
    private var chunkRetries = [Int: Int]()
    private var chunkRanges  = [Int: (start: Int64, end: Int64)]()
    private var pendingChunks = Set<Int>()
    private var hasFailed = false
    private var outputURL: URL!
    private var continuation: CheckedContinuation<URL, Error>?

    init(url: URL, headers: [String: String], chunkCount: Int = 16, maxRetries: Int = 3) {
        self.url = url
        self.headers = headers
        self.chunkCount = chunkCount
        self.maxRetries = maxRetries
        super.init()
        let config = URLSessionConfiguration.default
        config.httpMaximumConnectionsPerHost = 16
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 3600 * 12
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    func download(to output: URL) async throws -> URL {
        outputURL = output
        let totalSize = await fetchContentLength()

        let actualChunkCount: Int
        if totalSize > 0 {
            let chunkSize = (totalSize + Int64(chunkCount) - 1) / Int64(chunkCount)
            var idx = 0
            var start: Int64 = 0
            while start < totalSize {
                let end = min(start + chunkSize - 1, totalSize - 1)
                chunkRanges[idx] = (start, end)
                chunkTotal[idx]   = end - start + 1
                chunkWritten[idx] = 0
                chunkRetries[idx] = 0
                pendingChunks.insert(idx)
                start = end + 1
                idx  += 1
            }
            actualChunkCount = idx
        } else {
            // Unknown Content-Length: single open-ended range.
            chunkRanges[0]  = (0, -1)
            chunkTotal[0]   = 0
            chunkWritten[0] = 0
            chunkRetries[0] = 0
            pendingChunks.insert(0)
            actualChunkCount = 1
        }

        for i in 0..<actualChunkCount {
            chunkFiles[i] = FileManager.default.temporaryDirectory
                .appendingPathComponent("\(UUID().uuidString)_chunk\(i).tmp")
        }

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont
            for i in 0..<actualChunkCount { self.launchTask(chunkIndex: i) }
        }
    }

    // MARK: - Task management

    private func launchTask(chunkIndex: Int) {
        guard let range = chunkRanges[chunkIndex],
              let tempURL = chunkFiles[chunkIndex] else { return }

        // Fresh empty temp file.
        try? FileManager.default.removeItem(at: tempURL)
        FileManager.default.createFile(atPath: tempURL.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: tempURL) else {
            failAll(with: URLError(.cannotCreateFile))
            return
        }

        // YouTube's CDN throttles HTTP Range-header-only requests at ~200 KB/s.
        // Adding a `range=` query parameter skips throttling (this is the trick yt-dlp uses).
        let rangedURL = urlWithRangeParam(url, start: range.start, end: range.end >= 0 ? range.end : nil)
        var req = URLRequest(url: rangedURL)
        if range.end >= 0 {
            req.setValue("bytes=\(range.start)-\(range.end)", forHTTPHeaderField: "Range")
        } else {
            req.setValue("bytes=0-", forHTTPHeaderField: "Range")
        }
        applyHeaders(to: &req)

        let task = session.dataTask(with: req)

        lock.lock()
        chunkHandles[chunkIndex]          = handle
        chunkWritten[chunkIndex]          = 0
        taskToChunk[task.taskIdentifier]  = chunkIndex
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
        if http.statusCode == 206 || http.statusCode == 200 {
            completionHandler(.allow)
        } else {
            completionHandler(.cancel)
        }
    }

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.lock()
        let index = taskToChunk[dataTask.taskIdentifier]
        lock.unlock()
        guard let index else { return }

        lock.lock()
        let handle = chunkHandles[index]
        lock.unlock()
        guard let handle else { return }

        handle.write(data)

        lock.lock()
        chunkWritten[index] = (chunkWritten[index] ?? 0) + Int64(data.count)
        let written = chunkWritten.values.reduce(0, +)
        let total   = chunkTotal.values.reduce(0, +)
        lock.unlock()

        let fraction: Double = total > 0 ? min(1, Double(written) / Double(total)) : 0
        if let cb = onProgress {
            Task { @MainActor in cb(fraction) }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        lock.lock()
        guard let index = taskToChunk.removeValue(forKey: task.taskIdentifier) else {
            lock.unlock()
            return
        }
        let handle = chunkHandles.removeValue(forKey: index)
        lock.unlock()

        try? handle?.close()

        let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        let succeeded  = error == nil && (statusCode == 206 || statusCode == 200)

        if succeeded {
            lock.lock()
            pendingChunks.remove(index)
            let allDone = pendingChunks.isEmpty && !hasFailed
            lock.unlock()

            if allDone { finalizeDownload() }
        } else {
            lock.lock()
            let retries     = chunkRetries[index] ?? 0
            let canRetry    = retries < maxRetries && !hasFailed
            lock.unlock()

            if canRetry {
                lock.lock()
                chunkRetries[index] = retries + 1
                lock.unlock()
                let delay = pow(2.0, Double(retries))
                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.launchTask(chunkIndex: index)
                }
            } else {
                failAll(with: error ?? URLError(.badServerResponse))
            }
        }
    }

    // MARK: - Finalization

    private func finalizeDownload() {
        do {
            let count = chunkRanges.count

            if FileManager.default.fileExists(atPath: outputURL.path) {
                try FileManager.default.removeItem(at: outputURL)
            }
            FileManager.default.createFile(atPath: outputURL.path, contents: nil)
            let outHandle = try FileHandle(forWritingTo: outputURL)

            for i in 0..<count {
                guard let src = chunkFiles[i] else { throw URLError(.cannotOpenFile) }
                let inHandle = try FileHandle(forReadingFrom: src)
                while true {
                    let chunk = inHandle.readData(ofLength: 1_048_576)
                    if chunk.isEmpty { break }
                    outHandle.write(chunk)
                }
                try? inHandle.close()
            }
            try? outHandle.close()
            cleanupTempFiles()

            lock.lock()
            let cont = continuation
            continuation = nil
            lock.unlock()
            cont?.resume(returning: outputURL)
        } catch {
            failAll(with: error)
        }
    }

    private func failAll(with error: Error) {
        lock.lock()
        guard !hasFailed else { lock.unlock(); return }
        hasFailed = true
        let cont = continuation
        continuation = nil
        lock.unlock()

        cleanupTempFiles()
        cont?.resume(throwing: error)
    }

    private func cleanupTempFiles() {
        lock.lock()
        let files = Array(chunkFiles.values)
        chunkFiles.removeAll()
        lock.unlock()
        files.forEach { try? FileManager.default.removeItem(at: $0) }
    }

    // MARK: - Helpers

    private func fetchContentLength() async -> Int64 {
        var req = URLRequest(url: url)
        req.httpMethod = "HEAD"
        applyHeaders(to: &req)
        guard let (_, response) = try? await URLSession.shared.data(for: req),
              let http = response as? HTTPURLResponse else { return 0 }
        // Content-Length header comes back as a String in allHeaderFields
        let raw = http.allHeaderFields["Content-Length"] ?? http.allHeaderFields["content-length"]
        if let str = raw as? String { return Int64(str) ?? 0 }
        if let num = raw as? NSNumber { return num.int64Value }
        return 0
    }

    private func applyHeaders(to request: inout URLRequest) {
        for (key, value) in headers { request.setValue(value, forHTTPHeaderField: key) }
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
