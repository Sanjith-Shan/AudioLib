import Foundation
import CoreData

actor SyncService {
    static let shared = SyncService()

    private var lastPushTimes: [UUID: Date] = [:]
    private var lastPullTime: Date = .distantPast
    private let pushInterval: TimeInterval = 5
    private let pullCooldown: TimeInterval = 15

    private init() {}

    // MARK: - Push (called on every saveProgress)

    func pushProgress(bookID: UUID,
                      progressSeconds: Double,
                      title: String,
                      sourceURL: String,
                      durationSeconds: Double,
                      audioFilename: String,
                      artFilename: String?) async {
        let now = Date()
        if let last = lastPushTimes[bookID], now.timeIntervalSince(last) < pushInterval { return }
        lastPushTimes[bookID] = now

        guard let url = endpoint("/sync/progress") else { return }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.timeoutInterval = 2

        let payload: [String: Any] = [
            "bookID": bookID.uuidString,
            "progressSeconds": progressSeconds,
            "lastPlayedAt": ISO8601DateFormatter().string(from: now),
            "title": title,
            "sourceURL": sourceURL,
            "durationSeconds": durationSeconds,
            "audioFilename": audioFilename,
            "artFilename": artFilename ?? ""
        ]
        guard let body = try? JSONSerialization.data(withJSONObject: payload) else { return }
        req.httpBody = body
        try? await URLSession.shared.data(for: req)
    }

    // MARK: - Pull (called on foreground)

    func pullAndMerge() async {
        let now = Date()
        guard now.timeIntervalSince(lastPullTime) >= pullCooldown else { return }
        lastPullTime = now

        guard let url = endpoint("/sync/state") else { return }
        var req = URLRequest(url: url)
        req.timeoutInterval = 2

        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              (resp as? HTTPURLResponse)?.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let booksDict = json["books"] as? [String: [String: Any]],
              !booksDict.isEmpty else { return }

        let bgCtx = PersistenceController.shared.container.newBackgroundContext()
        bgCtx.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        let newBookIDs: [UUID] = await bgCtx.perform {
            var ids: [UUID] = []
            let fmt = ISO8601DateFormatter()

            for (bookIDString, entry) in booksDict {
                guard let bookID = UUID(uuidString: bookIDString) else { continue }
                let progressSeconds = entry["progressSeconds"] as? Double ?? 0
                let lastPlayedAt = fmt.date(from: entry["lastPlayedAt"] as? String ?? "") ?? .distantPast

                let fetchReq = NSFetchRequest<Book>(entityName: "Book")
                fetchReq.predicate = NSPredicate(format: "id == %@", bookID as CVarArg)

                if let existing = (try? bgCtx.fetch(fetchReq))?.first {
                    if lastPlayedAt > (existing.lastPlayedAt ?? .distantPast) {
                        existing.progressSeconds = progressSeconds
                        existing.lastPlayedAt = lastPlayedAt
                    }
                } else {
                    let sourceURL = entry["sourceURL"] as? String ?? ""
                    guard !sourceURL.isEmpty else { continue }

                    let book = Book(context: bgCtx)
                    book.id = bookID
                    book.title = entry["title"] as? String ?? ""
                    book.sourceURL = sourceURL
                    book.audioFilename = entry["audioFilename"] as? String ?? ""
                    let art = entry["artFilename"] as? String ?? ""
                    book.artFilename = art.isEmpty ? nil : art
                    book.durationSeconds = entry["durationSeconds"] as? Double ?? 0
                    book.progressSeconds = progressSeconds
                    book.lastPlayedAt = lastPlayedAt
                    book.dateAdded = Date()
                    book.playbackRate = 1.0
                    book.seriesIndex = 0

                    if !FileStore.hasAudioFile(for: bookID) {
                        ids.append(bookID)
                    }
                }
            }

            try? bgCtx.save()
            return ids
        }

        guard !newBookIDs.isEmpty else { return }
        Task { @MainActor in
            let ctx = PersistenceController.shared.container.viewContext
            for bookID in newBookIDs {
                let fetchReq = NSFetchRequest<Book>(entityName: "Book")
                fetchReq.predicate = NSPredicate(format: "id == %@", bookID as CVarArg)
                if let book = (try? ctx.fetch(fetchReq))?.first {
                    await DownloadManager.shared.reDownloadAudio(for: book)
                }
            }
        }
    }

    // MARK: - Helpers

    private func endpoint(_ path: String) -> URL? {
        let host = UserDefaults.standard.string(forKey: "audiolib.companionHost") ?? "localhost"
        let port = UserDefaults.standard.integer(forKey: "audiolib.companionPort")
        return URL(string: "http://\(host):\(port == 0 ? 8787 : port)\(path)")
    }
}
