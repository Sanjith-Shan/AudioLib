import CoreData
import Foundation
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// Observes CloudKit remote-change notifications and triggers auto re-download
/// for Books that arrived from another device but don't yet have local audio.
@MainActor
final class CloudSyncObserver: ObservableObject {
    static let shared = CloudSyncObserver()

    private let context: NSManagedObjectContext
    private var lastTokenData: Data? {
        get { UserDefaults.standard.data(forKey: "cloudSync.lastHistoryToken") }
        set { UserDefaults.standard.set(newValue, forKey: "cloudSync.lastHistoryToken") }
    }

    private init() {
        self.context = PersistenceController.shared.container.viewContext
    }

    func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteChange),
            name: .NSPersistentStoreRemoteChange,
            object: PersistenceController.shared.container.persistentStoreCoordinator
        )

        #if os(macOS)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForeground),
            name: NSApplication.willBecomeActiveNotification,
            object: nil
        )
        #else
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        #endif
    }

    @objc private func handleRemoteChange(_ notification: Notification) {
        processHistory()
    }

    @objc private func handleForeground() {
        scanForMissingAudio()
    }

    // MARK: - Persistent History Processing

    private func processHistory() {
        let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest
        historyFetchRequest?.predicate = NSPredicate(value: true)

        var lastToken: NSPersistentHistoryToken? = nil
        if let data = lastTokenData {
            lastToken = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }

        let fetchHistoryRequest = NSPersistentHistoryChangeRequest.fetchHistory(after: lastToken)

        context.perform { [weak self] in
            guard let self else { return }
            guard let result = try? self.context.execute(fetchHistoryRequest) as? NSPersistentHistoryResult,
                  let transactions = result.result as? [NSPersistentHistoryTransaction] else { return }

            for transaction in transactions {
                guard let changes = transaction.changes else { continue }
                for change in changes where change.changedObjectID.entity.name == "Book" {
                    if change.changeType == .insert {
                        if let book = try? self.context.existingObject(with: change.changedObjectID) as? Book {
                            self.handleRemoteBookInsert(book)
                        }
                    }
                }
            }

            // Store the last token
            if let lastTransaction = transactions.last {
                let tokenData = try? NSKeyedArchiver.archivedData(withRootObject: lastTransaction.token, requiringSecureCoding: true)
                self.lastTokenData = tokenData
            }

            // Dedup any duplicates that may have arrived
            self.deduplicateBooks()
        }
    }

    private func handleRemoteBookInsert(_ book: Book) {
        let bookID = book.id
        guard !FileStore.hasAudioFile(for: bookID) else { return }

        Task { @MainActor in
            await DownloadManager.shared.reDownloadAudio(for: book)
        }
    }

    // MARK: - Foreground Scan

    private func scanForMissingAudio() {
        context.perform { [weak self] in
            guard let self else { return }
            let request = NSFetchRequest<Book>(entityName: "Book")
            guard let books = try? self.context.fetch(request) else { return }

            for book in books {
                let bookID = book.id
                guard !FileStore.hasAudioFile(for: bookID),
                      !book.sourceURL.isEmpty else { continue }

                Task { @MainActor in
                    await DownloadManager.shared.reDownloadAudio(for: book)
                }
            }
        }
    }

    // MARK: - Deduplication

    private func deduplicateBooks() {
        let request = NSFetchRequest<Book>(entityName: "Book")
        guard let allBooks = try? context.fetch(request) else { return }

        let grouped = Dictionary(grouping: allBooks) { $0.id.uuidString }
        for (_, duplicates) in grouped where duplicates.count > 1 {
            let sorted = duplicates.sorted { ($0.dateAdded) < ($1.dateAdded) }
            let keeper = sorted.first!
            for dupe in sorted.dropFirst() {
                // Transfer higher progress to keeper
                if dupe.progressSeconds > keeper.progressSeconds {
                    keeper.progressSeconds = dupe.progressSeconds
                }
                // Re-link bookmarks and chapters
                (dupe.bookmarks as? Set<Bookmark>)?.forEach { $0.book = keeper }
                (dupe.chapters as? Set<Chapter>)?.forEach { $0.book = keeper }
                context.delete(dupe)
            }
        }
        try? context.save()
    }
}
