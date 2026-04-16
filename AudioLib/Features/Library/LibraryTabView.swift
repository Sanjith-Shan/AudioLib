import SwiftUI
import CoreData

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
    @Environment(AppRouter.self) private var router
    @Environment(\.managedObjectContext) private var context

    private var filteredBooks: [Book] {
        if searchText.isEmpty { return Array(books) }
        return books.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            ($0.author?.localizedCaseInsensitiveContains(searchText) ?? false)
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    EmptyStateView(
                        iconName: "books.vertical.fill",
                        title: "Your Library",
                        subtitle: "Downloaded audiobooks will appear here",
                        actionTitle: "Download one",
                        action: { router.selectedTab = 0 }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(filteredBooks) { book in
                                LibraryRow(book: book)
                                    .padding(.horizontal, Theme.Spacing.md)
                                    .onTapGesture {
                                        router.currentBookID = book.id
                                        router.showingPlayer = true
                                    }
                                    .contextMenu {
                                        Button { showingEditSheet = book } label: {
                                            Label("Edit Info", systemImage: "pencil")
                                        }
                                        Button(role: .destructive) { deleteBook(book) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                        .padding(.vertical, Theme.Spacing.sm)
                    }
                    .searchable(text: $searchText, prompt: "Search library")
                }
            }
            .background(Theme.Colors.white)
            .navigationTitle("Library")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingSettings = true } label: {
                        Image(systemName: "gearshape")
                            .foregroundStyle(Theme.Colors.dark)
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
