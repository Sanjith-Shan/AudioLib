#if os(macOS)
import SwiftUI
import CoreData

/// Desktop library: Continue-Listening hero + cover grid (or list) with a
/// per-view toolbar and a collapsible book inspector on the right.
struct MacLibraryView: View {
    @Bindable var model: MacAppModel

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Book.lastPlayedAt, ascending: false),
            NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)
        ],
        animation: .default
    ) private var books: FetchedResults<Book>

    @AppStorage("audiolib.librarySortOrder") private var sortOrderRaw = LibrarySortOrder.recentlyAdded.rawValue
    @Environment(AppRouter.self) private var router
    @Environment(\.managedObjectContext) private var context

    @State private var editingBook: Book?

    private var sortOrder: LibrarySortOrder { LibrarySortOrder(rawValue: sortOrderRaw) ?? .recentlyAdded }

    // MARK: - Filtering per sidebar section

    private var sectionBooks: [Book] {
        let all = Array(books)
        switch model.selection {
        case .continueListening:
            return all.filter { $0.lastPlayedAt != nil && $0.progressSeconds > 0 && $0.progressFraction < 0.99 }
        case .recentlyAdded:
            let cutoff = Date().addingTimeInterval(-14 * 86_400)
            return all.filter { $0.dateAdded > cutoff }
        case .finished:
            return all.filter { $0.durationSeconds > 0 && $0.progressFraction >= 0.99 }
        case .series(let name):
            return all.filter { $0.series == name }
        default:
            return all
        }
    }

    private var sortedBooks: [Book] {
        switch sortOrder {
        case .recentlyAdded: return sectionBooks.sorted { $0.dateAdded > $1.dateAdded }
        case .lastPlayed:    return sectionBooks.sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
        case .titleAZ:       return sectionBooks.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .authorAZ:      return sectionBooks.sorted { ($0.author ?? "").localizedCaseInsensitiveCompare($1.author ?? "") == .orderedAscending }
        }
    }

    private var continueBook: Book? {
        Array(books)
            .filter { $0.lastPlayedAt != nil && $0.progressSeconds > 0 && $0.progressFraction < 0.99 }
            .sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
            .first
    }

    private var inspectorBook: Book? {
        if let id = model.inspectorBookID ?? PlayerController.shared.currentBook?.id {
            return Array(books).first { $0.id == id }
        }
        return nil
    }

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            HStack(spacing: 0) {
                content
                if model.inspectorVisible, let book = inspectorBook {
                    MacBookInspector(book: book, model: model)
                        .environment(\.managedObjectContext, context)
                }
            }
        }
        .background(Theme.Colors.paper)
        .sheet(item: $editingBook) { book in
            BookEditSheet(book: book)
                .environment(\.managedObjectContext, context)
                .frame(minWidth: 420, minHeight: 520)
        }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        MToolbar(title: model.selection.title, subtitle: "\(sectionBooks.count) books") {
            HStack(spacing: 8) {
                Menu {
                    Picker("Sort by", selection: $sortOrderRaw) {
                        ForEach(LibrarySortOrder.allCases) { Text($0.label).tag($0.rawValue) }
                    }
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .menuStyle(.borderlessButton)
                .fixedSize()

                MSegmented(value: $model.libraryViewMode, options: [
                    (.grid, "square.grid.2x2"), (.list, "list.bullet")
                ])

                MIconButton(systemImage: "sidebar.trailing", active: model.inspectorVisible,
                            help: "Toggle Inspector") { model.inspectorVisible.toggle() }
            }
        }
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        if sectionBooks.isEmpty {
            emptyState
        } else if model.libraryViewMode == .grid {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    if model.selection == .allBooks, let cb = continueBook {
                        MacContinueHero(book: cb,
                                        onResume: { MacPlayback.play(cb) },
                                        onOpen: { select(cb) })
                            .padding(.bottom, 28)
                    }
                    HStack(alignment: .firstTextBaseline) {
                        Text("All Books").font(.serif(20, weight: .bold)).foregroundStyle(Theme.Colors.ink)
                        Spacer()
                        Text("Sorted by \(sortOrder.label)").font(.ui(12)).foregroundStyle(Theme.Colors.inkSoft)
                    }
                    .padding(.bottom, 14)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 132, maximum: 168), spacing: 22)],
                              alignment: .leading, spacing: 24) {
                        ForEach(sortedBooks, id: \.id) { book in
                            MacBookCard(book: book,
                                        isCurrent: PlayerController.shared.currentBook?.id == book.id,
                                        onPlay: { MacPlayback.play(book); select(book) },
                                        onSelect: { select(book) })
                                .contextMenu { cardMenu(book) }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 36)
            }
        } else {
            MacLibraryList(books: sortedBooks,
                           currentID: PlayerController.shared.currentBook?.id,
                           onPlay: { MacPlayback.play($0); select($0) },
                           onSelect: { select($0) },
                           menu: { cardMenu($0) })
        }
    }

    @ViewBuilder
    private func cardMenu(_ book: Book) -> some View {
        Button { MacPlayback.play(book); select(book) } label: { Label("Play", systemImage: "play.fill") }
        Button { select(book) } label: { Label("Open in Inspector", systemImage: "sidebar.trailing") }
        Button { editingBook = book } label: { Label("Edit Info", systemImage: "pencil") }
        Button { revealInFinder(book) } label: { Label("Show in Finder", systemImage: "folder") }
        Divider()
        Button(role: .destructive) { deleteBook(book) } label: { Label("Delete", systemImage: "trash") }
    }

    private var emptyState: some View {
        EmptyStateView(
            iconName: "books.vertical.fill",
            title: "Your library is empty",
            subtitle: "Downloaded audiobooks appear here. Anything you add on iPhone syncs over automatically.",
            actionTitle: "Go to Downloads",
            action: { model.selection = .downloadsActive }
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions

    private func select(_ book: Book) {
        model.inspectorBookID = book.id
        model.inspectorVisible = true
    }

    private func revealInFinder(_ book: Book) {
        let url = book.audioURL
        if FileManager.default.fileExists(atPath: url.path) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    private func deleteBook(_ book: Book) {
        if PlayerController.shared.currentBook?.id == book.id {
            PlayerController.shared.stop()
            router.currentBookID = nil
        }
        if model.inspectorBookID == book.id { model.inspectorBookID = nil }
        FileStore.deleteBook(id: book.id)
        context.delete(book)
        try? context.save()
    }
}

// MARK: - Continue Listening hero strip

private struct MacContinueHero: View {
    @ObservedObject var book: Book
    let onResume: () -> Void
    let onOpen: () -> Void

    private var remaining: String {
        DurationFormatter.string(from: max(0, book.durationSeconds - book.progressSeconds))
    }

    var body: some View {
        HStack(spacing: 22) {
            CoverArtView(book: book, size: 132, cornerRadius: 10)
            VStack(alignment: .leading, spacing: 4) {
                Text("CONTINUE LISTENING")
                    .font(.ui(10.5, weight: .bold)).tracking(1.2)
                    .foregroundStyle(Theme.Colors.paperFg.opacity(0.55))
                Text(book.title).font(.serif(28, weight: .bold)).foregroundStyle(Theme.Colors.paperFg).lineLimit(1)
                if let author = book.author {
                    Text(author).font(.ui(14)).foregroundStyle(Theme.Colors.paperFg.opacity(0.7))
                }
                HStack(spacing: 14) {
                    Button(action: onResume) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.fill").font(.system(size: 11))
                            Text("Resume · \(remaining) left").font(.ui(13, weight: .semibold))
                        }
                        .foregroundStyle(Theme.Colors.ink)
                        .padding(.horizontal, 18).padding(.vertical, 8)
                        .background(Theme.Colors.paperFg)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }.buttonStyle(.plain)
                    Button(action: onOpen) {
                        Text("Open").font(.ui(13, weight: .semibold))
                            .foregroundStyle(Theme.Colors.paperFg)
                            .padding(.horizontal, 14).padding(.vertical, 8)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Theme.Colors.paperFg.opacity(0.25), lineWidth: 0.5))
                    }.buttonStyle(.plain)
                }
                .padding(.top, 10)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 10) {
                Text("\(Int(book.progressFraction * 100))% complete")
                    .font(.ui(11)).foregroundStyle(Theme.Colors.paperFg.opacity(0.6))
                ProgressBarView(value: book.progressFraction, height: 3,
                                color: Theme.Colors.paperFg, track: Theme.Colors.paperFg.opacity(0.18))
                    .frame(width: 180)
                Text("\(DurationFormatter.format(seconds: book.progressSeconds)) / \(DurationFormatter.format(seconds: book.durationSeconds))")
                    .font(.mono(10.5)).foregroundStyle(Theme.Colors.paperFg.opacity(0.55))
            }
            .frame(minWidth: 160, alignment: .trailing)
        }
        .padding(22)
        .background(Theme.Gradients.continueListening)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: Color(hex: 0x11332E, opacity: 0.18), radius: 20, y: 4)
    }
}

// MARK: - Grid card

private struct MacBookCard: View {
    @ObservedObject var book: Book
    let isCurrent: Bool
    let onPlay: () -> Void
    let onSelect: () -> Void

    @State private var hovering = false

    private var inProgress: Bool { book.progressFraction > 0 && book.progressFraction < 0.999 }
    private var finished: Bool { book.durationSeconds > 0 && book.progressFraction >= 0.999 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                CoverArtView(book: book, size: 132, cornerRadius: 8)

                if hovering {
                    RoundedRectangle(cornerRadius: 8).fill(.black.opacity(0.35))
                        .frame(width: 132, height: 132)
                    Button(action: onPlay) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink)
                            .frame(width: 44, height: 44)
                            .background(Theme.Colors.paperFg)
                            .clipShape(Circle())
                    }.buttonStyle(.plain)
                }

                if inProgress {
                    VStack {
                        Spacer()
                        ProgressBarView(value: book.progressFraction, height: 3,
                                        color: Theme.Colors.paperFg, track: .black.opacity(0.45))
                            .padding(.horizontal, 6).padding(.bottom, 6)
                    }
                    .frame(width: 132, height: 132)
                }
                if finished {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold)).foregroundStyle(.white)
                                .frame(width: 20, height: 20).background(Theme.Colors.teal).clipShape(Circle())
                        }
                        Spacer()
                    }
                    .frame(width: 132, height: 132).padding(6)
                }
            }

            Text(book.title).font(.ui(13, weight: .semibold)).foregroundStyle(Theme.Colors.ink)
                .lineLimit(2).frame(maxWidth: 132, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
            if let author = book.author {
                Text(author).font(.ui(11.5)).foregroundStyle(Theme.Colors.inkSoft).lineLimit(1)
            }
            if inProgress {
                Text(DurationFormatter.string(from: max(0, book.durationSeconds - book.progressSeconds)) + " left")
                    .font(.mono(10.5)).foregroundStyle(Theme.Colors.inkMute)
            }
        }
        .frame(width: 132, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(count: 2) { onPlay() }
        .onTapGesture { onSelect() }
        .onHover { hovering = $0 }
    }
}
#endif
