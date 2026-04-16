import SwiftUI
import CoreData

struct BookmarksSheet: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var context
    @State private var player = PlayerController.shared

    var sortedBookmarks: [Bookmark] {
        (book.bookmarks as? Set<Bookmark>)?.sorted { $0.timeSeconds < $1.timeSeconds } ?? []
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedBookmarks.isEmpty {
                    EmptyStateView(
                        iconName: "bookmark",
                        title: "No Bookmarks",
                        subtitle: "Tap the bookmark icon while listening to save a position"
                    )
                } else {
                    List {
                        ForEach(sortedBookmarks) { bookmark in
                            Button {
                                player.seek(to: bookmark.timeSeconds)
                                dismiss()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(DurationFormatter.format(seconds: bookmark.timeSeconds))
                                            .font(.bodySemibold)
                                            .foregroundStyle(Theme.Colors.dark)
                                        if let note = bookmark.note, !note.isEmpty {
                                            Text(note)
                                                .font(.caption)
                                                .foregroundStyle(Theme.Colors.midSlate)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Theme.Colors.coolGray)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteBookmarks)
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private func deleteBookmarks(at offsets: IndexSet) {
        let bookmarksToDelete = offsets.map { sortedBookmarks[$0] }
        bookmarksToDelete.forEach { context.delete($0) }
        try? context.save()
    }
}
