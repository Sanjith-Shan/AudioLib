import SwiftUI
import CoreData

struct MiniPlayer: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.managedObjectContext) private var context
    @State private var player = PlayerController.shared

    private var currentBook: Book? {
        guard let id = router.currentBookID else { return nil }
        let req = NSFetchRequest<Book>(entityName: "Book")
        req.predicate = NSPredicate(format: "id == %@", id as CVarArg)
        req.fetchLimit = 1
        return try? context.fetch(req).first
    }

    var body: some View {
        if let book = currentBook, !router.showingPlayer {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    CoverArtView(book: book, size: 42, cornerRadius: 8)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(book.title)
                            .font(.ui(13, weight: .semibold))
                            .foregroundStyle(Theme.Colors.paperFg)
                            .lineLimit(1)
                        if let author = book.author {
                            Text(author)
                                .font(.ui(11.5))
                                .foregroundStyle(Theme.Colors.paperFg.opacity(0.55))
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    Button {
                        player.togglePlayPause()
                    } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Theme.Colors.paperFg)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.12))
                            .clipShape(Circle())
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(player.isPlaying ? "Pause" : "Play")
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)

                // hairline progress along bottom inset
                ProgressBarView(
                    value: book.progressFraction,
                    height: 2,
                    color: Theme.Colors.teal,
                    track: Color.white.opacity(0.08)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 2)
            }
            .background(Theme.Colors.ink)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: Color(hex: 0x1B1814, opacity: 0.22), radius: 22, y: 6)
            .padding(.horizontal, Theme.Spacing.sm)
            .contentShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture {
                router.showingPlayer = true
            }
            .accessibilityElement(children: .contain)
            .accessibilityHint("Tap to open the full player")
        }
    }
}
