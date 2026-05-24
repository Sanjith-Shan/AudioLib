#if os(macOS)
import SwiftUI
import CoreData

/// Mac Downloads: dark add-card + Active list (live) + Recently completed.
struct MacDownloadsView: View {
    @ObservedObject private var manager = DownloadManager.shared
    @Environment(\.managedObjectContext) private var context

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)],
        animation: .default
    ) private var books: FetchedResults<Book>

    @State private var urlText = ""
    @State private var starting = false
    @State private var errorText: String?

    private var active: [ActiveDownload] {
        manager.activeDownloads.values.sorted { $0.bookID.uuidString < $1.bookID.uuidString }
    }
    private var recentlyCompleted: [Book] {
        let cutoff = Date().addingTimeInterval(-7 * 86_400)
        return books.filter { $0.dateAdded > cutoff }.prefix(8).map { $0 }
    }

    private var subtitle: String {
        let n = active.count
        let c = recentlyCompleted.count
        return "\(n) active · \(c) recently completed"
    }

    var body: some View {
        VStack(spacing: 0) {
            MToolbar(title: "Downloads", subtitle: subtitle)
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    addCard.padding(.bottom, 24)

                    if !active.isEmpty {
                        sectionLabel("Active")
                        card { ForEach(active, id: \.bookID) { dl in
                            MacDownloadRow(dl: dl,
                                           onCancel: { manager.cancelDownload(bookID: dl.bookID) },
                                           onListen: { playBook(dl.bookID) })
                            divider(after: dl.bookID, in: active.map(\.bookID))
                        } }
                    }

                    if !recentlyCompleted.isEmpty {
                        sectionLabel("Recently completed").padding(.top, active.isEmpty ? 0 : 24)
                        card { ForEach(recentlyCompleted, id: \.id) { book in
                            completedRow(book)
                            divider(after: book.id, in: recentlyCompleted.map(\.id))
                        } }
                    }

                    if active.isEmpty && recentlyCompleted.isEmpty {
                        emptyState.padding(.top, 40)
                    }
                }
                .padding(.horizontal, 24).padding(.top, 20).padding(.bottom, 24)
            }
        }
        .background(Theme.Colors.paper)
    }

    // MARK: - Add card

    private var addCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                Image(systemName: "link")
                    .font(.system(size: 18)).foregroundStyle(Theme.Colors.paperFg)
                    .frame(width: 44, height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add an audiobook from YouTube")
                        .font(.ui(14, weight: .semibold)).foregroundStyle(Theme.Colors.paperFg)
                    TextField("youtube.com/watch?v=…", text: $urlText)
                        .textFieldStyle(.plain)
                        .font(.mono(13)).foregroundStyle(Theme.Colors.paperFg)
                        .padding(.horizontal, 12).padding(.vertical, 9)
                        .background(Color.white.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.1), lineWidth: 0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                        .onSubmit(startDownload)
                }
                Button(action: startDownload) {
                    HStack(spacing: 6) {
                        if starting { ProgressView().controlSize(.small) }
                        else { Image(systemName: "arrow.down.circle").font(.system(size: 14, weight: .semibold)) }
                        Text(starting ? "Adding…" : "Download").font(.ui(13, weight: .semibold))
                    }
                    .foregroundStyle(urlText.isEmpty ? Theme.Colors.paperFg.opacity(0.5) : Theme.Colors.ink)
                    .padding(.horizontal, 18).padding(.vertical, 10)
                    .background(urlText.isEmpty ? Color.white.opacity(0.18) : Theme.Colors.paperFg)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
                .buttonStyle(.plain).disabled(urlText.isEmpty || starting)
            }
            if let errorText {
                Text(errorText).font(.ui(12)).foregroundStyle(Color(hex: 0xFF8A80))
                    .padding(.top, 10)
            }
        }
        .padding(20)
        .background(Theme.Colors.ink)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func startDownload() {
        let text = urlText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !starting else { return }
        starting = true; errorText = nil
        Task {
            do { try await manager.startDownload(urlString: text); urlText = "" }
            catch { errorText = error.localizedDescription }
            starting = false
        }
    }

    // MARK: - Completed row

    private func completedRow(_ book: Book) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 18)).foregroundStyle(Theme.Colors.teal)
                .frame(width: 28, height: 28)
                .background(Theme.Colors.tealSoft).clipShape(RoundedRectangle(cornerRadius: 8))
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title).font(.ui(13, weight: .semibold)).foregroundStyle(Theme.Colors.ink).lineLimit(1)
                Text("Added to Library · \(DurationFormatter.format(seconds: book.durationSeconds))")
                    .font(.ui(11.5)).foregroundStyle(Theme.Colors.inkSoft)
            }
            Spacer()
            Text(relative(book.dateAdded)).font(.ui(11)).foregroundStyle(Theme.Colors.inkMute)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
    }

    // MARK: - Bits

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased()).font(.ui(11, weight: .bold)).tracking(0.5)
            .foregroundStyle(Theme.Colors.inkMute)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 4).padding(.bottom, 8)
    }

    private func card<C: View>(@ViewBuilder _ content: () -> C) -> some View {
        VStack(spacing: 0) { content() }
            .background(Theme.Colors.card)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func divider(after id: UUID, in ids: [UUID]) -> some View {
        if id != ids.last { Rectangle().fill(Theme.Colors.hair).frame(height: 0.5) }
    }

    private var emptyState: some View {
        EmptyStateView(iconName: "arrow.down.circle", title: "No downloads",
                       subtitle: "Paste a YouTube link above to add an audiobook.",
                       actionTitle: nil, action: nil)
    }

    private func playBook(_ id: UUID) {
        if let book = books.first(where: { $0.id == id }) { MacPlayback.play(book) }
    }

    private func relative(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter(); f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Active download row

private struct MacDownloadRow: View {
    let dl: ActiveDownload
    let onCancel: () -> Void
    let onListen: () -> Void

    private var isCompanion: Bool {
        dl.downloadPhase == .macDownloading || dl.downloadPhase == .transferring
    }

    private var title: String {
        dl.metadata.title.isEmpty ? dl.sourceURL : dl.metadata.title
    }

    private var stateLine: String {
        switch dl.downloadPhase {
        case .fetchingMetadata: return "Fetching info…"
        case .macDownloading:   return "Mac downloading · Companion" + etaSuffix
        case .transferring:     return "Transferring to iPhone · Companion"
        case .onDevice:         return "Downloading" + speedSuffix + etaSuffix
        case .finalizing:       return "Finalizing…"
        }
    }
    private var speedSuffix: String {
        guard dl.speedBytesPerSec > 0 else { return "" }
        let mbps = dl.speedBytesPerSec / 1_000_000
        return mbps >= 1 ? String(format: " · %.1f MB/s", mbps)
                         : String(format: " · %.0f KB/s", dl.speedBytesPerSec / 1024)
    }
    private var etaSuffix: String {
        guard let eta = dl.eta, eta.isFinite, eta > 0 else { return "" }
        let m = Int(eta) / 60
        return m >= 1 ? " · ~\(m) min left" : " · ~\(Int(eta))s left"
    }
    private var sourceLabel: String {
        isCompanion ? "Companion" : "On-device · \(dl.metadata.fileExtension)"
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8).fill(Theme.Colors.cardSoft).frame(width: 32, height: 32)
                if dl.downloadPhase == .fetchingMetadata {
                    ProgressView().controlSize(.small)
                } else {
                    Image(systemName: isCompanion ? "desktopcomputer" : "arrow.down.circle")
                        .font(.system(size: 16)).foregroundStyle(Theme.Colors.ink)
                }
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.ui(13.5, weight: .semibold)).foregroundStyle(Theme.Colors.ink).lineLimit(1)
                Text(stateLine).font(.ui(11.5)).foregroundStyle(Theme.Colors.inkSoft).lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if dl.downloadPhase != .fetchingMetadata {
                VStack(spacing: 4) {
                    ProgressBarView(value: dl.progress, height: 4, color: Theme.Colors.ink)
                    HStack {
                        Text("\(Int(dl.progress * 100))%").font(.mono(10.5)).foregroundStyle(Theme.Colors.inkMute)
                        Spacer()
                        Text(sourceLabel).font(.mono(10.5)).foregroundStyle(Theme.Colors.inkMute)
                    }
                }
                .frame(width: 140)
            }

            if dl.isStreamingReady {
                Button(action: onListen) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill").font(.system(size: 9))
                        Text("Listen").font(.ui(11, weight: .semibold))
                    }
                    .foregroundStyle(Theme.Colors.tealInk)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(Theme.Colors.tealSoft).clipShape(RoundedRectangle(cornerRadius: 7))
                }.buttonStyle(.plain)
            }

            Button(action: onCancel) {
                Image(systemName: "xmark").font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.inkMute).frame(width: 22, height: 22)
            }.buttonStyle(.plain).help("Cancel")
        }
        .padding(.horizontal, 16).padding(.vertical, 14)
    }
}
#endif
