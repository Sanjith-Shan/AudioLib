import SwiftUI
import CoreData

enum LibrarySortOrder: String, CaseIterable, Identifiable {
    case recentlyAdded = "recentlyAdded"
    case lastPlayed = "lastPlayed"
    case titleAZ = "titleAZ"
    case authorAZ = "authorAZ"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recentlyAdded: return "Recently Added"
        case .lastPlayed:    return "Last Played"
        case .titleAZ:       return "Title A–Z"
        case .authorAZ:      return "Author A–Z"
        }
    }
}

struct LibraryTabView: View {
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Book.lastPlayedAt, ascending: false),
            NSSortDescriptor(keyPath: \Book.dateAdded, ascending: false)
        ],
        animation: .default
    ) private var books: FetchedResults<Book>

    @State private var searchText = ""
    @State private var showingSettings = false
    @State private var showingEditSheet: Book? = nil
    @AppStorage("audiolib.librarySortOrder") private var sortOrderRaw = LibrarySortOrder.recentlyAdded.rawValue
    @Environment(AppRouter.self) private var router
    @Environment(\.managedObjectContext) private var context

    private var sortOrder: LibrarySortOrder {
        LibrarySortOrder(rawValue: sortOrderRaw) ?? .recentlyAdded
    }

    private var sortedBooks: [Book] {
        let all = Array(books)
        switch sortOrder {
        case .recentlyAdded:
            return all.sorted { $0.dateAdded > $1.dateAdded }
        case .lastPlayed:
            return all.sorted { (a, b) in
                let ad = a.lastPlayedAt ?? .distantPast
                let bd = b.lastPlayedAt ?? .distantPast
                return ad > bd
            }
        case .titleAZ:
            return all.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .authorAZ:
            return all.sorted { ($0.author ?? "").localizedCaseInsensitiveCompare($1.author ?? "") == .orderedAscending }
        }
    }

    private var filteredBooks: [Book] {
        let base = sortedBooks
        if searchText.isEmpty { return base }
        return base.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.author?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    private var continueListeningBook: Book? {
        books
            .filter { $0.lastPlayedAt != nil && $0.progressSeconds > 0 && $0.progressFraction < 0.99 }
            .sorted { ($0.lastPlayedAt ?? .distantPast) > ($1.lastPlayedAt ?? .distantPast) }
            .first
    }

    private func openPlayer(_ book: Book) {
        router.currentBookID = book.id
        router.showingPlayer = true
    }

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    EmptyStateView(
                        iconName: "books.vertical.fill",
                        title: "Your Library",
                        subtitle: "Downloaded audiobooks will appear here.",
                        actionTitle: "Download one",
                        action: { router.selectedTab = 0 }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if searchText.isEmpty, let book = continueListeningBook {
                                ContinueListeningBanner(book: book) { openPlayer(book) }
                                    .padding(.horizontal, Theme.Spacing.md)
                                    .padding(.top, Theme.Spacing.xs)
                                    .padding(.bottom, 18)
                            }

                            SectionHeaderView(title: "All Books", trailing: "\(filteredBooks.count)")

                            VStack(spacing: 0) {
                                ForEach(Array(filteredBooks.enumerated()), id: \.element.id) { index, book in
                                    LibraryRow(book: book) { openPlayer(book) }
                                        .contentShape(Rectangle())
                                        .onTapGesture { openPlayer(book) }
                                        .contextMenu {
                                            Button { showingEditSheet = book } label: {
                                                Label("Edit Info", systemImage: "pencil")
                                            }
                                            Button(role: .destructive) { deleteBook(book) } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    if index < filteredBooks.count - 1 {
                                        Rectangle()
                                            .fill(Theme.Colors.hair)
                                            .frame(height: 0.5)
                                            .padding(.leading, 92)
                                    }
                                }
                            }
                            .background(Theme.Colors.card)
                            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                            .padding(.horizontal, Theme.Spacing.md)
                        }
                        .padding(.bottom, 168)
                    }
                    .searchable(text: $searchText, prompt: "Search title or author")
                }
            }
            .background(Theme.Colors.paper.ignoresSafeArea())
            .navigationTitle("Library")
            .iOSNavigationBarLargeTitles()
            .toolbar {
                ToolbarItem(placement: .trailingBar) {
                    Menu {
                        Picker("Sort by", selection: $sortOrderRaw) {
                            ForEach(LibrarySortOrder.allCases) { option in
                                Text(option.label).tag(option.rawValue)
                            }
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .foregroundStyle(Theme.Colors.ink)
                    }
                }
                ToolbarItem(placement: .trailingBar) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.ink)
                    }
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
                    .environment(\.managedObjectContext, context)
            }
            .sheet(item: $showingEditSheet) { book in
                BookEditSheet(book: book)
                    .environment(\.managedObjectContext, context)
            }
        }
    }

    private func deleteBook(_ book: Book) {
        PlayerController.shared.stop()
        if AppRouter.shared.currentBookID == book.id {
            AppRouter.shared.currentBookID = nil
            AppRouter.shared.showingPlayer = false
        }
        FileStore.deleteBook(id: book.id)
        context.delete(book)
        try? context.save()
    }
}

// MARK: - Continue Listening banner

private struct ContinueListeningBanner: View {
    @ObservedObject var book: Book
    let onResume: () -> Void

    private var remaining: String {
        DurationFormatter.string(from: max(0, book.durationSeconds - book.progressSeconds)) + " left"
    }

    var body: some View {
        HStack(spacing: 14) {
            CoverArtView(book: book, size: 84, cornerRadius: 10)

            VStack(alignment: .leading, spacing: 0) {
                Text("CONTINUE LISTENING")
                    .font(.ui(10, weight: .bold))
                    .tracking(1.2)
                    .foregroundStyle(Theme.Colors.paperFg.opacity(0.55))
                    .padding(.bottom, 4)

                Text(book.title)
                    .font(.ui(17, weight: .bold))
                    .foregroundStyle(Theme.Colors.paperFg)
                    .lineLimit(1)

                if let author = book.author {
                    Text(author)
                        .font(.ui(13))
                        .foregroundStyle(Theme.Colors.paperFg.opacity(0.7))
                        .lineLimit(1)
                        .padding(.top, 2)
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        ProgressBarView(
                            value: book.progressFraction,
                            height: 3,
                            color: Theme.Colors.paperFg,
                            track: Theme.Colors.paperFg.opacity(0.18)
                        )
                        Text(remaining)
                            .font(.mono(11))
                            .foregroundStyle(Theme.Colors.paperFg.opacity(0.6))
                    }

                    Button(action: onResume) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Theme.Colors.ink)
                            .frame(width: 44, height: 44)
                            .background(Theme.Colors.paperFg)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 12)
            }
        }
        .padding(16)
        .background(Theme.Gradients.continueListening)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous))
        .shadow(color: Color(hex: 0x11332E, opacity: 0.22), radius: 24, y: 8)
        .contentShape(RoundedRectangle(cornerRadius: Theme.Radius.cardLarge))
        .onTapGesture { onResume() }
    }
}
