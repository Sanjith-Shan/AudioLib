import Foundation
import AVFoundation
import CoreData

// MARK: - Supporting types

enum DownloadPhase {
    case fetchingMetadata
    case macDownloading   // yt-dlp running on Mac
    case transferring     // file moving from Mac to iPhone
    case onDevice         // downloading directly from YouTube
    case finalizing
}

struct ActiveDownload {
    let bookID: UUID
    let jobID: UUID
    var metadata: YTMetadata
    let sourceURL: String
    var progress: Double = 0
    var retryCount: Int = 0
    var speedBytesPerSec: Double = 0
    var bytesTotal: Int64 = 0
    var bytesDownloaded: Int64 = 0
    var eta: TimeInterval? = nil
    var isStreamingReady: Bool = false
    var downloadPhase: DownloadPhase = .fetchingMetadata
    var transferStartDate: Date? = nil
}

enum DownloadError: LocalizedError {
    case alreadyInLibrary
    case timeout
    case resolverFailed(String)

    var errorDescription: String? {
        switch self {
        case .alreadyInLibrary:
            return "This audiobook is already in your library."
        case .timeout:
            return "Could not reach YouTube. Check your connection or configure the companion server in Settings."
        case .resolverFailed(let message):
            return message
        }
    }
}

extension Notification.Name {
    static let audioLibStreamingReady = Notification.Name("audiolib.streamingReady")
}

// MARK: - DownloadManager

@MainActor
final class DownloadManager: NSObject, ObservableObject {

    static let shared = DownloadManager()

    @Published var activeDownloads: [UUID: ActiveDownload] = [:]

    var progressiveManagers: [UUID: ProgressiveDownloadManager] = [:]
    var streamingLoaders: [UUID: StreamingResourceLoader] = [:]

    private override init() {
        super.init()
        wireBackgroundSession()
    }

    // MARK: - Public API

    func startDownload(urlString: String) async throws {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            throw YouTubeResolverError.invalidURL
        }

        let context = PersistenceController.shared.container.viewContext
        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "sourceURL == %@", trimmed)
        if let count = try? context.count(for: req), count > 0 {
            throw DownloadError.alreadyInLibrary
        }

        let bookID = UUID()
        let jobID  = UUID()

        let jobIDCopy    = jobID
        let trimmedCopy  = trimmed
        await PersistenceController.shared.container.performBackgroundTask { bgCtx in
            DownloadJobStore.createJob(id: jobIDCopy, sourceURL: trimmedCopy, in: bgCtx)
        }

        updateJob(jobID: jobID, state: "fetching-metadata", progress: 0)

        // If a companion server is configured we ALWAYS prefer it for metadata
        // too. The on-device YouTubeKit resolver has been observed to hang
        // indefinitely on YouTube's network, which surfaces to the user as
        // "Fetching info…" forever. Wrapping with a 25s timeout guarantees
        // we fail fast no matter which resolver we end up using.
        let useCompanion = await CompanionDownloader.shared.isConfigured
        let resolver: any YouTubeResolver
        if useCompanion {
            let host = UserDefaults.standard.string(forKey: "audiolib.companionHost") ?? "localhost"
            let port = UserDefaults.standard.integer(forKey: "audiolib.companionPort")
            resolver = CompanionServerResolver(host: host, port: port == 0 ? 8787 : port)
        } else {
            resolver = OnDeviceYouTubeResolver()
        }

        let metadata: YTMetadata
        do {
            metadata = try await withTimeout(seconds: 25) {
                try await resolver.resolve(url: url)
            }
        } catch {
            let message = (error as? URLError)?.code == .timedOut
                ? DownloadError.timeout.localizedDescription
                : error.localizedDescription
            updateJob(jobID: jobID, state: "failed", progress: 0, errorMessage: message)
            activeDownloads.removeValue(forKey: bookID)
            throw (error as? URLError)?.code == .timedOut ? DownloadError.timeout : error
        }

        activeDownloads[bookID] = ActiveDownload(
            bookID: bookID,
            jobID: jobID,
            metadata: metadata,
            sourceURL: trimmed
        )

        Task { await downloadThumbnail(bookID: bookID, thumbnailURL: metadata.thumbnailURL) }

        updateJob(jobID: jobID, state: "downloading", progress: 0)
        if useCompanion {
            await startCompanionDownload(
                bookID: bookID,
                jobID: jobID,
                metadata: metadata,
                sourceURL: trimmed
            )
        } else {
            await startOnDeviceDownload(
                bookID: bookID,
                jobID: jobID,
                metadata: metadata,
                sourceURL: trimmed
            )
        }
    }

    func cancelDownload(bookID: UUID) {
        let ext = activeDownloads[bookID]?.metadata.fileExtension ?? "m4a"
        progressiveManagers[bookID]?.cancel()
        progressiveManagers.removeValue(forKey: bookID)
        streamingLoaders.removeValue(forKey: bookID)
        BackgroundDownloadSession.shared.cancel(bookID: bookID.uuidString)
        if let dl = activeDownloads[bookID] {
            updateJob(jobID: dl.jobID, state: "cancelled", progress: 0)
        }
        activeDownloads.removeValue(forKey: bookID)

        let partialURL = FileStore.audioURL(for: bookID, fileExtension: ext.isEmpty ? "m4a" : ext)
        try? FileManager.default.removeItem(at: partialURL)
    }

    func reconnectOnLaunch() {
        BackgroundDownloadSession.shared.reconnectExistingDownloads()
    }

    /// Re-downloads audio for a Book that arrived from CloudKit but has no local file.
    /// Uses a transient jobID (no DownloadJob persisted) so CloudKit doesn't replicate the job.
    func reDownloadAudio(for book: Book) async {
        let bookID = book.id
        guard !book.sourceURL.isEmpty,
              let url = URL(string: book.sourceURL) else { return }

        guard activeDownloads[bookID] == nil else { return }

        let fakeJobID = UUID()

        let useCompanion = await CompanionDownloader.shared.isConfigured
        let resolver: any YouTubeResolver
        if useCompanion {
            let host = UserDefaults.standard.string(forKey: "audiolib.companionHost") ?? "localhost"
            let port = UserDefaults.standard.integer(forKey: "audiolib.companionPort")
            resolver = CompanionServerResolver(host: host, port: port == 0 ? 8787 : port)
        } else {
            resolver = OnDeviceYouTubeResolver()
        }

        let metadata: YTMetadata
        do {
            metadata = try await withTimeout(seconds: 25) {
                try await resolver.resolve(url: url)
            }
        } catch {
            return
        }

        activeDownloads[bookID] = ActiveDownload(
            bookID: bookID,
            jobID: fakeJobID,
            metadata: metadata,
            sourceURL: book.sourceURL
        )

        Task { await downloadThumbnail(bookID: bookID, thumbnailURL: metadata.thumbnailURL) }

        if useCompanion {
            await startCompanionDownload(bookID: bookID, jobID: fakeJobID, metadata: metadata, sourceURL: book.sourceURL)
        } else {
            await startOnDeviceDownload(bookID: bookID, jobID: fakeJobID, metadata: metadata, sourceURL: book.sourceURL)
        }
    }

    // MARK: - Path A: Companion (Mac-side) download

    private func startCompanionDownload(
        bookID: UUID,
        jobID: UUID,
        metadata: YTMetadata,
        sourceURL: String
    ) async {
        do {
            let macJobID = try await CompanionDownloader.shared.startJob(youtubeURL: sourceURL)
            updateJob(jobID: jobID, state: "downloading", progress: 0)
            activeDownloads[bookID]?.downloadPhase = .macDownloading

            // Phase 1: poll Mac-side progress until yt-dlp finishes.
            pollLoop: while true {
                try await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s

                let progOpt = try? await CompanionDownloader.shared.pollProgress(jobID: macJobID)
                guard let prog = progOpt else { break pollLoop }

                if prog.status == "failed" {
                    updateJob(jobID: jobID, state: "failed", progress: 0, errorMessage: prog.error ?? "Companion server reported a failure.")
                    activeDownloads.removeValue(forKey: bookID)
                    return
                }

                // Phase 1 progress: Mac download = first 70% of total progress
                let totalFraction = prog.percent / 100.0 * 0.7
                if var dl = activeDownloads[bookID] {
                    dl.progress = totalFraction
                    dl.speedBytesPerSec = prog.speedBytesPerSec
                    dl.eta = prog.etaSeconds
                    dl.downloadPhase = .macDownloading
                    activeDownloads[bookID] = dl
                }
                updateJob(jobID: jobID, state: "downloading", progress: totalFraction)

                if prog.status == "done" { break pollLoop }
            }

            // Phase 2: transfer the finished file from Mac to iPhone.
            let ext = metadata.fileExtension.isEmpty ? "m4a" : metadata.fileExtension
            let outputURL = FileStore.audioURL(for: bookID, fileExtension: ext)

            let startDate = Date()
            if var dl = activeDownloads[bookID] {
                dl.downloadPhase = .transferring
                dl.transferStartDate = startDate
                dl.progress = 0.7
                dl.speedBytesPerSec = 0
                activeDownloads[bookID] = dl
            }

            let capturedBookID = bookID
            let capturedJobID = jobID

            try await CompanionDownloader.shared.downloadFile(
                jobID: macJobID,
                to: outputURL
            ) { [weak self] received, total in
                Task { @MainActor [weak self] in
                    guard let self, var dl = self.activeDownloads[capturedBookID] else { return }
                    let transferFraction = total > 0 ? Double(received) / Double(total) : 0
                    dl.progress = 0.7 + transferFraction * 0.3
                    dl.bytesDownloaded = received
                    if dl.bytesTotal == 0 && total > 0 { dl.bytesTotal = total }
                    let elapsed = max(0.1, Date().timeIntervalSince(dl.transferStartDate ?? startDate))
                    let speed = received > 0 ? Double(received) / elapsed : 0
                    dl.speedBytesPerSec = speed
                    dl.eta = (speed > 0 && total > received)
                        ? TimeInterval(Double(total - received) / speed)
                        : nil
                    self.activeDownloads[capturedBookID] = dl
                    self.updateJob(jobID: capturedJobID, state: "downloading", progress: dl.progress)
                }
            }

            // All bytes received. Finalize.
            finalizeProgressiveDownload(bookID: bookID)
        } catch {
            updateJob(jobID: jobID, state: "failed", progress: 0, errorMessage: error.localizedDescription)
            activeDownloads.removeValue(forKey: bookID)
        }
    }

    // MARK: - Path B: On-device direct download

    private func startOnDeviceDownload(
        bookID: UUID,
        jobID: UUID,
        metadata: YTMetadata,
        sourceURL: String
    ) async {
        activeDownloads[bookID]?.downloadPhase = .onDevice

        let ext = metadata.fileExtension.isEmpty ? "m4a" : metadata.fileExtension
        let contentLength = await fetchContentLength(url: metadata.audioStreamURL, headers: metadata.downloadHeaders)

        let outputURL = FileStore.audioURL(for: bookID, fileExtension: ext)

        let manager = ProgressiveDownloadManager(
            bookID: bookID,
            url: metadata.audioStreamURL,
            headers: metadata.downloadHeaders,
            totalBytes: contentLength,
            outputURL: outputURL
        )

        let loader = StreamingResourceLoader(progressiveManager: manager, fileExtension: ext)
        streamingLoaders[bookID] = loader
        progressiveManagers[bookID] = manager

        if contentLength > 0 {
            activeDownloads[bookID]?.bytesTotal = contentLength
        }

        wireProgressive(manager: manager, bookID: bookID)
        manager.start()
    }

    // MARK: - ProgressiveDownloadManager wiring

    private func wireProgressive(manager: ProgressiveDownloadManager, bookID: UUID) {
        manager.onProgress = { [weak self] fraction, speed, downloaded, total in
            Task { @MainActor [weak self] in
                guard let self, var dl = self.activeDownloads[bookID] else { return }
                dl.progress = fraction
                dl.speedBytesPerSec = speed
                dl.bytesDownloaded = downloaded
                if total > 0 { dl.bytesTotal = total }
                let remaining = max(0, dl.bytesTotal - downloaded)
                dl.eta = speed > 1024 ? TimeInterval(Double(remaining) / speed) : nil
                self.activeDownloads[bookID] = dl
                self.updateJob(jobID: dl.jobID, state: "downloading", progress: fraction)
            }
        }

        manager.onChunkWritten = { [weak self] in
            Task { @MainActor [weak self] in
                self?.streamingLoaders[bookID]?.chunkDidComplete()
            }
        }

        manager.onStreamingReady = { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, var dl = self.activeDownloads[bookID] else { return }
                dl.isStreamingReady = true
                self.activeDownloads[bookID] = dl

                let ext = dl.metadata.fileExtension.isEmpty ? "m4a" : dl.metadata.fileExtension
                if ext.lowercased() == "m4a" {
                    self.createPartialBook(bookID: bookID, download: dl, fileExtension: ext)
                }

                NotificationCenter.default.post(
                    name: .audioLibStreamingReady,
                    object: nil,
                    userInfo: ["bookID": bookID, "title": dl.metadata.title]
                )
            }
        }

        manager.onComplete = { [weak self] in
            Task { @MainActor [weak self] in
                self?.finalizeProgressiveDownload(bookID: bookID)
            }
        }

        manager.onFailed = { [weak self] error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let dl = self.activeDownloads[bookID] {
                    self.updateJob(jobID: dl.jobID, state: "failed", progress: 0, errorMessage: error.localizedDescription)
                }
                self.progressiveManagers.removeValue(forKey: bookID)
                self.streamingLoaders.removeValue(forKey: bookID)
                self.activeDownloads.removeValue(forKey: bookID)
            }
        }
    }

    private func wireBackgroundSession() {
        BackgroundDownloadSession.shared.onProgress = { [weak self] bookIDString, fraction, speed, downloaded, total in
            Task { @MainActor [weak self] in
                guard let self,
                      let bookID = UUID(uuidString: bookIDString),
                      var dl = self.activeDownloads[bookID] else { return }
                dl.progress = fraction
                dl.speedBytesPerSec = speed
                dl.bytesDownloaded = downloaded
                if total > 0 { dl.bytesTotal = total }
                let remaining = max(0, dl.bytesTotal - downloaded)
                dl.eta = speed > 1024 ? TimeInterval(Double(remaining) / speed) : nil
                self.activeDownloads[bookID] = dl
                self.updateJob(jobID: dl.jobID, state: "downloading", progress: fraction)
            }
        }

        BackgroundDownloadSession.shared.onBookFinished = { [weak self] bookIDString, url in
            Task { @MainActor [weak self] in
                guard let self, let bookID = UUID(uuidString: bookIDString) else { return }
                self.finalizeLegacyDownload(bookID: bookID, tempFileURL: url)
            }
        }

        BackgroundDownloadSession.shared.onBookNeedsReResolve = { [weak self] bookIDString in
            Task { @MainActor [weak self] in
                guard let self, let bookID = UUID(uuidString: bookIDString) else { return }
                await self.reResolveAndRestart(bookID: bookID)
            }
        }

        BackgroundDownloadSession.shared.onBookFailed = { [weak self] bookIDString, _ in
            Task { @MainActor [weak self] in
                guard let self, let bookID = UUID(uuidString: bookIDString) else { return }
                if let dl = self.activeDownloads[bookID] {
                    self.updateJob(jobID: dl.jobID, state: "failed", progress: 0)
                }
                self.activeDownloads.removeValue(forKey: bookID)
            }
        }
    }

    private func reResolveAndRestart(bookID: UUID) async {
        guard var dl = activeDownloads[bookID] else { return }
        dl.retryCount += 1
        if dl.retryCount > 2 {
            updateJob(jobID: dl.jobID, state: "failed", progress: 0)
            activeDownloads.removeValue(forKey: bookID)
            BackgroundDownloadSession.shared.cancel(bookID: bookID.uuidString)
            return
        }
        activeDownloads[bookID] = dl

        BackgroundDownloadSession.shared.cancel(bookID: bookID.uuidString)

        guard let url = URL(string: dl.sourceURL) else {
            updateJob(jobID: dl.jobID, state: "failed", progress: 0)
            activeDownloads.removeValue(forKey: bookID)
            return
        }

        let resolver = YouTubeResolverFactory.makeResolver()
        guard let fresh = try? await resolver.resolve(url: url) else {
            updateJob(jobID: dl.jobID, state: "failed", progress: 0)
            activeDownloads.removeValue(forKey: bookID)
            return
        }

        dl.metadata = fresh
        dl.progress = 0
        dl.bytesDownloaded = 0
        activeDownloads[bookID] = dl

        do {
            try await BackgroundDownloadSession.shared.startDownload(
                bookID: bookID.uuidString,
                streamURL: fresh.audioStreamURL,
                headers: fresh.downloadHeaders,
                fileExtension: fresh.fileExtension.isEmpty ? "m4a" : fresh.fileExtension,
                chunkCount: 8
            )
        } catch {
            updateJob(jobID: dl.jobID, state: "failed", progress: 0)
            activeDownloads.removeValue(forKey: bookID)
        }
    }

    // MARK: - Thumbnail

    private func downloadThumbnail(bookID: UUID, thumbnailURL: URL) async {
        let base = thumbnailURL.absoluteString
        let candidates: [URL] = [
            thumbnailURL,
            URL(string: base.replacingOccurrences(of: "maxresdefault", with: "hqdefault")) ?? thumbnailURL,
            URL(string: base.replacingOccurrences(of: "maxresdefault", with: "default")) ?? thumbnailURL
        ]

        for candidate in candidates {
            if let (data, response) = try? await URLSession.shared.data(from: candidate),
               let http = response as? HTTPURLResponse,
               http.statusCode == 200 {
                let tempURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(bookID.uuidString)_art.jpg")
                try? data.write(to: tempURL)
                try? FileStore.moveArt(from: tempURL, bookID: bookID)
                break
            }
        }
    }

    // MARK: - Finalize

    // Creates a Book row right after chunk 0 lands so the Library can show and
    // play the audio while the rest of the file is still streaming in.
    private func createPartialBook(bookID: UUID, download: ActiveDownload, fileExtension: String) {
        let ctx = PersistenceController.shared.container.viewContext

        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "id == %@", bookID as CVarArg)
        if let existing = try? ctx.fetch(req), !existing.isEmpty { return }

        let book = Book(context: ctx)
        book.id              = bookID
        book.title           = download.metadata.title
        book.author          = download.metadata.uploader == "Unknown" ? nil : download.metadata.uploader
        book.durationSeconds = download.metadata.durationSeconds
        book.progressSeconds = 0
        book.sourceURL       = download.sourceURL
        book.audioFilename   = "\(bookID.uuidString).\(fileExtension)"
        book.artFilename     = FileManager.default.fileExists(
            atPath: FileStore.artURL(for: bookID).path
        ) ? "\(bookID.uuidString).jpg" : nil
        book.dateAdded       = Date()
        book.playbackRate    = 1.0
        book.seriesIndex     = 0

        for ch in download.metadata.chapters {
            let chapter = Chapter(context: ctx)
            chapter.id           = UUID()
            chapter.title        = ch.title
            chapter.startSeconds = ch.startSeconds
            chapter.endSeconds   = 0
            chapter.book         = book
        }

        try? ctx.save()
    }

    private func finalizeProgressiveDownload(bookID: UUID) {
        guard let download = activeDownloads[bookID] else {
            progressiveManagers.removeValue(forKey: bookID)
            streamingLoaders.removeValue(forKey: bookID)
            return
        }

        updateJob(jobID: download.jobID, state: "finalizing", progress: 1.0)
        activeDownloads[bookID]?.downloadPhase = .finalizing

        let ext = download.metadata.fileExtension.isEmpty ? "m4a" : download.metadata.fileExtension
        let audioURL = FileStore.audioURL(for: bookID, fileExtension: ext)

        let capturedBookID    = bookID
        let capturedJobID     = download.jobID
        let capturedMetadata  = download.metadata
        let capturedSourceURL = download.sourceURL
        let capturedExt       = ext

        Task {
            let asset    = AVURLAsset(url: audioURL)
            let duration = (try? await asset.load(.duration).seconds) ?? 0

            await PersistenceController.shared.container.performBackgroundTask { bgCtx in
                let req = NSFetchRequest<Book>(entityName: "Book")
                req.predicate = NSPredicate(format: "id == %@", capturedBookID as CVarArg)

                let book: Book
                if let existing = try? bgCtx.fetch(req), let first = existing.first {
                    book = first
                    if let existingChapters = book.chapters as? Set<Chapter> {
                        for ch in existingChapters { bgCtx.delete(ch) }
                    }
                } else {
                    book = Book(context: bgCtx)
                    book.id              = capturedBookID
                    book.progressSeconds = 0
                    book.sourceURL       = capturedSourceURL
                    book.playbackRate    = 1.0
                    book.seriesIndex     = 0
                    book.dateAdded       = Date()
                }

                book.title           = capturedMetadata.title
                book.author          = capturedMetadata.uploader == "Unknown" ? nil : capturedMetadata.uploader
                book.durationSeconds = duration > 0 ? duration : capturedMetadata.durationSeconds
                book.audioFilename   = "\(capturedBookID.uuidString).\(capturedExt)"
                book.artFilename     = FileManager.default.fileExists(
                    atPath: FileStore.artURL(for: capturedBookID).path
                ) ? "\(capturedBookID.uuidString).jpg" : nil

                for ch in capturedMetadata.chapters {
                    let chapter = Chapter(context: bgCtx)
                    chapter.id           = UUID()
                    chapter.title        = ch.title
                    chapter.startSeconds = ch.startSeconds
                    chapter.endSeconds   = 0
                    chapter.book         = book
                }

                try? bgCtx.save()
            }

            await MainActor.run {
                LocalNotifications.scheduleDownloadComplete(bookTitle: capturedMetadata.title)
                self.updateJob(jobID: capturedJobID, state: "done", progress: 1.0)
                self.activeDownloads.removeValue(forKey: capturedBookID)
                self.progressiveManagers.removeValue(forKey: capturedBookID)
                self.streamingLoaders.removeValue(forKey: capturedBookID)
            }
        }
    }

    private func finalizeLegacyDownload(bookID: UUID, tempFileURL: URL) {
        guard let download = activeDownloads[bookID] else { return }

        updateJob(jobID: download.jobID, state: "finalizing", progress: 1.0)

        let ext = download.metadata.fileExtension.isEmpty ? "m4a" : download.metadata.fileExtension
        guard let audioURL = try? FileStore.moveAudio(from: tempFileURL, bookID: bookID, fileExtension: ext) else {
            updateJob(jobID: download.jobID, state: "failed", progress: 0)
            activeDownloads.removeValue(forKey: bookID)
            return
        }

        let capturedBookID    = bookID
        let capturedJobID     = download.jobID
        let capturedMetadata  = download.metadata
        let capturedSourceURL = download.sourceURL
        let capturedExt       = ext

        Task {
            let asset    = AVURLAsset(url: audioURL)
            let duration = (try? await asset.load(.duration).seconds) ?? 0

            await PersistenceController.shared.container.performBackgroundTask { bgCtx in
                let book = Book(context: bgCtx)
                book.id              = capturedBookID
                book.title           = capturedMetadata.title
                book.author          = capturedMetadata.uploader == "Unknown" ? nil : capturedMetadata.uploader
                book.durationSeconds = duration > 0 ? duration : capturedMetadata.durationSeconds
                book.progressSeconds = 0
                book.sourceURL       = capturedSourceURL
                book.audioFilename   = "\(capturedBookID.uuidString).\(capturedExt)"
                book.artFilename     = FileManager.default.fileExists(
                    atPath: FileStore.artURL(for: capturedBookID).path
                ) ? "\(capturedBookID.uuidString).jpg" : nil
                book.dateAdded       = Date()
                book.playbackRate    = 1.0
                book.seriesIndex     = 0

                for ch in capturedMetadata.chapters {
                    let chapter = Chapter(context: bgCtx)
                    chapter.id           = UUID()
                    chapter.title        = ch.title
                    chapter.startSeconds = ch.startSeconds
                    chapter.endSeconds   = 0
                    chapter.book         = book
                }

                try? bgCtx.save()
            }

            await MainActor.run {
                LocalNotifications.scheduleDownloadComplete(bookTitle: capturedMetadata.title)
                self.updateJob(jobID: capturedJobID, state: "done", progress: 1.0)
                self.activeDownloads.removeValue(forKey: capturedBookID)
            }
        }
    }

    // MARK: - Helpers

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

    private func updateJob(jobID: UUID, state: String, progress: Double, errorMessage: String? = nil) {
        let idCopy = jobID
        let msgCopy = errorMessage
        PersistenceController.shared.container.performBackgroundTask { ctx in
            let req = NSFetchRequest<DownloadJob>(entityName: "DownloadJob")
            req.predicate = NSPredicate(format: "id == %@", idCopy as CVarArg)
            if let job = (try? ctx.fetch(req))?.first {
                job.state    = state
                job.progress = progress
                if let msgCopy {
                    job.errorMessage = msgCopy
                } else if state != "failed" {
                    // Clear any stale error once the job is no longer failed.
                    job.errorMessage = nil
                }
                try? ctx.save()
            }
        }
    }
}

// MARK: - Free helpers

/// Runs `operation` and throws `URLError(.timedOut)` if it doesn't complete
/// within `seconds`. The losing child task is cancelled.
private func withTimeout<T: Sendable>(
    seconds: Double,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        group.addTask { try await operation() }
        group.addTask {
            try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
            throw URLError(.timedOut)
        }
        let result = try await group.next()!
        group.cancelAll()
        return result
    }
}
