import SwiftUI
import CoreData

struct MiniPlayer: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.managedObjectContext) private var context

    private var currentBook: Book? {
        guard let id = router.currentBookID else { return nil }
        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    var body: some View {
        if let book = currentBook, !router.showingPlayer {
            HStack(spacing: Theme.Spacing.md) {
                CoverArtView(book: book, size: 40, cornerRadius: 8)

                VStack(alignment: .leading, spacing: 2) {
                    Text(book.title)
                        .font(.bodySemibold)
                        .foregroundStyle(Theme.Colors.white)
                        .lineLimit(1)
                    if let author = book.author {
                        Text(author)
                            .font(.caption)
                            .foregroundStyle(Theme.Colors.white.opacity(0.7))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    PlayerController.shared.togglePlayPause()
                } label: {
                    Image(systemName: PlayerController.shared.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Theme.Colors.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.vertical, Theme.Spacing.sm)
            .background(Theme.Colors.dark)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardSmall))
            .padding(.horizontal, Theme.Spacing.sm)
            .onTapGesture {
                router.showingPlayer = true
            }
        }
    }
}
