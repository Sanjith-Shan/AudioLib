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
}
#endif
