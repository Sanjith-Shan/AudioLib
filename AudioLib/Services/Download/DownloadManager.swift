import Foundation
import AVFoundation
import CoreData

// MARK: - Supporting types

/// Metadata snapshot for a download that is in progress.
struct ActiveDownload {
    let bookID: UUID
    let jobID: UUID
    let metadata: YTMetadata
    let sourceURL: String        // original user-entered YouTube URL
    var progress: Double = 0
    var retryCount: Int = 0
}

enum DownloadError: LocalizedError {
    case alreadyInLibrary

    var errorDescription: String? {
        switch self {
        case .alreadyInLibrary:
            return "This audiobook is already in your library."
        }
    }
}

// MARK: - Thread-safe dictionary wrappers
// These must NOT be @MainActor so delegate methods (nonisolated) can safely read/write them.

private final class LockedDictionary<Key: Hashable, Value> {
    private var storage: [Key: Value] = [:]
    private let lock = NSLock()

    func get(_ key: Key) -> Value? {
        lock.lock(); defer { lock.unlock() }
        return storage[key]
    }

    @discardableResult
    func removeValue(forKey key: Key) -> Value? {
        lock.lock(); defer { lock.unlock() }
        return storage.removeValue(forKey: key)
    }

    func set(_ value: Value, forKey key: Key) {
        lock.lock(); defer { lock.unlock() }
        storage[key] = value
    }
}

// MARK: - DownloadManager

@MainActor
final class DownloadManager: NSObject, ObservableObject {

    static let shared = DownloadManager()

    // Published state consumed by SwiftUI
    @Published var activeDownloads: [UUID: ActiveDownload] = [:]

    // Background URLSession wired to self as delegate
    private var backgroundSession: URLSession!

    // Called by AppDelegate when the OS wakes the app for background events
    private var backgroundCompletionHandler: (() -> Void)?

    // These two must be nonisolated-accessible — use locked wrappers.
    // URLSessionDownloadTask.taskIdentifier -> bookID
    nonisolated(unsafe) private let taskToBook = LockedDictionary<Int, UUID>()
    // taskIdentifier -> last progress update time (for throttling)
    nonisolated(unsafe) private let lastProgressUpdate = LockedDictionary<Int, Date>()

    private override init() {
        super.init()
        let config = URLSessionConfiguration.background(withIdentifier: "com.sanjith.audiolib.bg")
        config.isDiscretionary = false
        config.sessionSendsLaunchEvents = true
        backgroundSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }

    // MARK: - Public API

    func handleBackgroundCompletion(_ handler: @escaping () -> Void) {
        backgroundCompletionHandler = handler
    }

    /// Validates the URL, resolves metadata, creates a DownloadJob, and starts the background download.
    func startDownload(urlString: String) async throws {
        let trimmed = urlString.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else {
            throw YouTubeResolverError.invalidURL
        }

        // Duplicate check against existing books (main context is fine here — we're on main actor)
        let context = PersistenceController.shared.container.viewContext
        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "sourceURL == %@", trimmed)
        if let count = try? context.count(for: req), count > 0 {
            throw DownloadError.alreadyInLibrary
        }

        let bookID = UUID()
        let jobID = UUID()

        // Create the DownloadJob synchronously on a background context.
        // `performBackgroundTask` has an async overload in iOS 15+; use it directly.
        let jobIDCopy = jobID
        let trimmedCopy = trimmed
        await PersistenceController.shared.container.performBackgroundTask { bgCtx in
            DownloadJobStore.createJob(id: jobIDCopy, sourceURL: trimmedCopy, in: bgCtx)
        }

        // Fetch metadata
        updateJob(jobID: jobID, state: "fetching-metadata", progress: 0)
        let resolver = YouTubeResolverFactory.makeResolver()
        let metadata = try await resolver.resolve(url: url)

        // Kick off the actual download
        updateJob(jobID: jobID, state: "downloading", progress: 0)
        await beginAudioDownload(bookID: bookID, jobID: jobID, metadata: metadata, sourceURL: trimmed)
    }

    // MARK: - Private helpers

    private func beginAudioDownload(
        bookID: UUID,
        jobID: UUID,
        metadata: YTMetadata,
        sourceURL: String
    ) async {
        var request = URLRequest(url: metadata.audioStreamURL)
        request.timeoutInterval = 0  // no per-request timeout for large files

        let task = backgroundSession.downloadTask(with: request)
        taskToBook.set(bookID, forKey: task.taskIdentifier)

        activeDownloads[bookID] = ActiveDownload(
            bookID: bookID,
            jobID: jobID,
            metadata: metadata,
            sourceURL: sourceURL
        )

        task.resume()

        // Thumbnail download runs in the foreground — it's a tiny file.
        Task {
            await downloadThumbnail(bookID: bookID, thumbnailURL: metadata.thumbnailURL)
        }
    }

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

    /// Called when a download task finishes successfully.
    private func finalizeDownload(bookID: UUID, tempFileURL: URL) {
        guard let download = activeDownloads[bookID] else { return }

        updateJob(jobID: download.jobID, state: "finalizing", progress: 1.0)

        guard let audioURL = try? FileStore.moveAudio(from: tempFileURL, bookID: bookID) else {
            updateJob(jobID: download.jobID, state: "failed", progress: 0)
            activeDownloads.removeValue(forKey: bookID)
            return
        }

        // Capture primitive values to cross actor/thread boundaries safely
        let capturedBookID = bookID
        let capturedJobID = download.jobID
        let capturedMetadata = download.metadata
        let capturedSourceURL = download.sourceURL

        Task {
            let asset = AVURLAsset(url: audioURL)
            let duration = (try? await asset.load(.duration).seconds) ?? 0

            await PersistenceController.shared.container.performBackgroundTask { bgCtx in
                let book = Book(context: bgCtx)
                book.id = capturedBookID
                book.title = capturedMetadata.title
                book.author = capturedMetadata.uploader == "Unknown" ? nil : capturedMetadata.uploader
                book.durationSeconds = duration > 0 ? duration : capturedMetadata.durationSeconds
                book.progressSeconds = 0
                book.sourceURL = capturedSourceURL
                book.audioFilename = "\(capturedBookID.uuidString).m4a"
                book.artFilename = FileManager.default.fileExists(
                    atPath: FileStore.artURL(for: capturedBookID).path
                ) ? "\(capturedBookID.uuidString).jpg" : nil
                book.dateAdded = Date()
                book.playbackRate = 1.0
                book.seriesIndex = 0

                for ch in capturedMetadata.chapters {
                    let chapter = Chapter(context: bgCtx)
                    chapter.id = UUID()
                    chapter.title = ch.title
                    chapter.startSeconds = ch.startSeconds
                    chapter.endSeconds = 0  // Phase 4 will compute end times
                    chapter.book = book
                }

                try? bgCtx.save()
            }

            await MainActor.run {
                self.updateJob(jobID: capturedJobID, state: "done", progress: 1.0)
                self.activeDownloads.removeValue(forKey: capturedBookID)
            }
        }
    }

    /// Updates the DownloadJob's state and progress on a background Core Data context.
    private func updateJob(jobID: UUID, state: String, progress: Double) {
        let idCopy = jobID
        PersistenceController.shared.container.performBackgroundTask { ctx in
            let req = NSFetchRequest<DownloadJob>(entityName: "DownloadJob")
            req.predicate = NSPredicate(format: "id == %@", idCopy as CVarArg)
            if let job = (try? ctx.fetch(req))?.first {
                job.state = state
                job.progress = progress
                try? ctx.save()
            }
        }
    }

    /// Re-resolves the original YouTube URL and retries the download.
    /// Only called when HTTP 403/410 is received and retryCount < 1.
    private func retryDownload(bookID: UUID) {
        guard var download = activeDownloads[bookID] else { return }
        download.retryCount += 1
        activeDownloads[bookID] = download

        let sourceURL = download.sourceURL
        let bookIDCopy = bookID
        let jobIDCopy = download.jobID

        Task {
            guard let url = URL(string: sourceURL) else { return }
            let resolver = YouTubeResolverFactory.makeResolver()
            guard let freshMetadata = try? await resolver.resolve(url: url) else {
                await MainActor.run {
                    self.updateJob(jobID: jobIDCopy, state: "failed", progress: 0)
                    self.activeDownloads.removeValue(forKey: bookIDCopy)
                }
                return
            }

            // Update stored metadata with fresh stream URL (preserve counters)
            await MainActor.run {
                if let existing = self.activeDownloads[bookIDCopy] {
                    let refreshed = ActiveDownload(
                        bookID: existing.bookID,
                        jobID: existing.jobID,
                        metadata: freshMetadata,
                        sourceURL: existing.sourceURL,
                        progress: 0,
                        retryCount: existing.retryCount
                    )
                    self.activeDownloads[bookIDCopy] = refreshed
                }
            }

            await beginAudioDownload(
                bookID: bookIDCopy,
                jobID: jobIDCopy,
                metadata: freshMetadata,
                sourceURL: sourceURL
            )
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let bookID = taskToBook.removeValue(forKey: downloadTask.taskIdentifier)
        guard let bookID else { return }

        // The file at `location` is deleted when this delegate returns,
        // so copy it to a stable temp path first.
        let stableTemp = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(bookID.uuidString)_audio_dl.tmp")
        try? FileManager.default.removeItem(at: stableTemp)
        try? FileManager.default.copyItem(at: location, to: stableTemp)

        Task { @MainActor in
            self.finalizeDownload(bookID: bookID, tempFileURL: stableTemp)
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }

        let taskID = downloadTask.taskIdentifier
        let now = Date()

        // Throttle: only propagate updates every 500 ms
        let last = lastProgressUpdate.get(taskID)
        let shouldUpdate = last == nil || now.timeIntervalSince(last!) >= 0.5
        if shouldUpdate { lastProgressUpdate.set(now, forKey: taskID) }
        guard shouldUpdate else { return }

        guard let bookID = taskToBook.get(taskID) else { return }

        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        Task { @MainActor in
            guard var download = self.activeDownloads[bookID] else { return }
            download.progress = fraction
            self.activeDownloads[bookID] = download
            self.updateJob(jobID: download.jobID, state: "downloading", progress: fraction)
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        // If the task completed without error at the Foundation level,
        // didFinishDownloadingTo already handled success — check for HTTP-level errors.
        let statusCode = (task.response as? HTTPURLResponse)?.statusCode ?? 0
        let isHttpError = statusCode == 403 || statusCode == 410

        // If there's no Foundation error AND no retriable HTTP error, nothing to do.
        guard error != nil || isHttpError else { return }

        let taskID = task.taskIdentifier
        guard let bookID = taskToBook.removeValue(forKey: taskID) else { return }

        Task { @MainActor in
            if isHttpError, let download = self.activeDownloads[bookID], download.retryCount < 1 {
                self.retryDownload(bookID: bookID)
            } else {
                if let download = self.activeDownloads[bookID] {
                    self.updateJob(jobID: download.jobID, state: "failed", progress: 0)
                }
                self.activeDownloads.removeValue(forKey: bookID)
            }
        }
    }

    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            self.backgroundCompletionHandler?()
            self.backgroundCompletionHandler = nil
        }
    }
}
