#if os(macOS)
import Foundation

/// Single entry point for starting playback on macOS so the library grid,
/// now-playing pane, toolbar, and menu commands all behave identically.
enum MacPlayback {
    /// Loads (if needed) and plays a book, routing it into the now-playing pane.
    static func play(_ book: Book) {
        AppRouter.shared.currentBookID = book.id
        let player = PlayerController.shared
        if player.currentBook?.id != book.id {
            player.load(book: book)
        }
        player.play()
    }

    /// Selects a book into the now-playing pane without forcing playback.
    static func select(_ book: Book) {
        AppRouter.shared.currentBookID = book.id
        let player = PlayerController.shared
        if player.currentBook?.id != book.id {
            player.load(book: book)
        }
    }

    static func nextChapter() {
        let player = PlayerController.shared
        guard let chapters = player.currentBook?.chaptersArray, !chapters.isEmpty else { return }
        if let next = chapters.first(where: { $0.startSeconds > player.currentTime + 1 }) {
            player.seek(to: next.startSeconds)
        }
    }

    static func previousChapter() {
        let player = PlayerController.shared
        guard let chapters = player.currentBook?.chaptersArray, !chapters.isEmpty else { return }
        // back to start of current chapter, or previous if we're near the top
        let priors = chapters.filter { $0.startSeconds < player.currentTime - 2 }
        player.seek(to: priors.last?.startSeconds ?? 0)
    }

    /// "1.5×" / "2×" formatting for the speed pill.
    static func rateLabel(_ rate: Float) -> String {
        if rate.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(rate))×"
        }
        return String(format: "%g×", rate)
    }
}
#endif
