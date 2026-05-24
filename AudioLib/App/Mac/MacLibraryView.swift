#if os(macOS)
import SwiftUI
import CoreData

/// Desktop-native library: a resizable cover-art grid with hover-to-play,
/// search, and sort — the Mac counterpart to the iPhone's LibraryTabView list.
struct MacLibraryView: View {
    var model: MacAppModel

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Book.lastPlayedAt, ascending: false),
            NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)
        ],
        animation: .default
    ) private var books: FetchedResults<Book>

    @State private var searchText = ""
    @AppStorage("audiolib.librarySortOrder") private var sortOrderRaw = LibrarySortOrder.recentlyAdded.rawValue
    @Environment(AppRouter.self) private var router
    @Environment(\.managedObjectContext) private var context

    @State private var editingBook: Book?

    private var sortOrder: LibrarySortOrder {
        LibrarySortOrder(rawValue: sortOrderRaw) ?? .recentlyAdded
    }

    private var sortedBooks: [Book] {
        let all = Array(books)
        switch sortOrder {
        case .recentlyAdded:
            return all.sorted { $0.dateAdded > $1.dateAdded }
        case .lastPlayed:
            return all.sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
        case .titleAZ:
            return all.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .authorAZ:
            return all.sorted { ($0.author ?? "").localizedCaseInsensitiveCompare($1.author ?? "") == .orderedAscending }
        }
    }

    private var filteredBooks: [Book] {
        let base = sortedBooks
        guard !searchText.isEmpty else { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.author?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private let columns = [GridItem(.adaptive(minimum: 168, maximum: 220), spacing: 22)]

    var body: some View {
        Group {
            if books.isEmpty {
                EmptyStateView(
                    iconName: "books.vertical.fill",
                    title: "Your Library",
                    subtitle: "Downloaded audiobooks will appear here. Anything you add on iPhone syncs here automatically.",
                    actionTitle: "Go to Download",
                    action: { router.selectedTab = 0 }
                )
            } else {
                ScrollView {
                    LazyVGrid(columns: columns, alignment: .leading, spacing: 26) {
                        ForEach(filteredBooks, id: \.id) { book in
                            MacBookTile(
                                book: book,
                                isCurrent: router.currentBookID == book.id,
                                onPlay: { MacPlayback.play(book) }
                            )
                            .contextMenu {
                                Button { MacPlayback.play(book) } label: {
                                    Label("Play", systemImage: "play.fill")
                                }
                                Button { editingBook = book } label: {
                                    Label("Edit Info", systemImage: "pencil")
                                }
                                Divider()
                                Button(role: .destructive) { deleteBook(book) } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(28)
                }
            }
        }
        .background(Theme.Colors.paper)
        .navigationTitle("Library")
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search title or author")
        .toolbar {
            ToolbarItem {
                Menu {
                    Picker("Sort by", selection: $sortOrderRaw) {
                        ForEach(LibrarySortOrder.allCases) { option in
                            Text(option.label).tag(option.rawValue)
                        }
                    }
                } label: {
                    Label("Sort", systemImage: "line.3.horizontal.decrease")
                }
            }
        }
        .sheet(item: $editingBook) { book in
            BookEditSheet(book: book)
                .environment(\.managedObjectContext, context)
                .frame(minWidth: 420, minHeight: 520)
        }
    }

    private func deleteBook(_ book: Book) {
        if router.currentBookID == book.id {
            PlayerController.shared.stop()
            router.currentBookID = nil
        }
        FileStore.deleteBook(id: book.id)
        context.delete(book)
        try? context.save()
    }
}

// MARK: - Grid tile

private struct MacBookTile: View {
    @ObservedObject var book: Book
    let isCurrent: Bool
    let onPlay: () -> Void

    @State private var hovering = false

    private var isFinished: Bool { book.durationSeconds > 0 && book.progressFraction >= 0.999 }

    private var statusLabel: String {
        if isFinished { return "Finished" }
        if book.progressSeconds <= 0 { return "New" }
        return DurationFormatter.string(from: max(0, book.durationSeconds - book.progressSeconds)) + " left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                CoverArtView(book: book, size: 168, cornerRadius: 12)

                // hover/playing play overlay
                if hovering || isCurrent {
                    Circle()
                        .fill(.black.opacity(0.55))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Image(systemName: isCurrent ? "speaker.wave.2.fill" : "play.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        )
                }
            }
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Theme.Colors.teal, lineWidth: isCurrent ? 2.5 : 0)
            )

            Text(book.title)
                .font(.ui(13.5, weight: .semibold))
                .foregroundStyle(Theme.Colors.ink)
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            if let author = book.author {
                Text(author)
                    .font(.ui(11.5))
                    .foregroundStyle(Theme.Colors.inkSoft)
                    .lineLimit(1)
            }

            HStack(spacing: 6) {
                ProgressBarView(
                    value: book.progressFraction,
                    height: 2.5,
                    color: isFinished ? Theme.Colors.teal : Theme.Colors.ink
                )
                Text(statusLabel)
                    .font(.mono(10))
                    .foregroundStyle(Theme.Colors.inkMute)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .frame(width: 168, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onPlay() }
        .onTapGesture { onPlay() }
        .onHover { hovering = $0 }
        .help("Play \(book.title)")
    }
}
#endif
