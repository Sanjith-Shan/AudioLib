#if os(macOS)
import SwiftUI

/// Persistent trailing pane (Music.app style) that stays visible while you
/// browse the library. Reuses the shared player subcomponents so behavior
/// matches the iPhone full-screen player exactly.
struct MacNowPlayingPane: View {
    @State private var player = PlayerController.shared

    @State private var showingSpeedSheet = false
    @State private var showingSleepSheet = false
    @State private var showingBookmarks = false
    @State private var showingChapters = false

    var body: some View {
        ZStack {
            Theme.Gradients.player.ignoresSafeArea()

            if let book = player.currentBook {
                content(for: book)
            } else {
                emptyState
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSpeedSheet) { SpeedSheet() }
        .sheet(isPresented: $showingSleepSheet) { SleepTimerSheet() }
        .sheet(isPresented: $showingBookmarks) {
            if let book = player.currentBook { BookmarksSheet(book: book) }
        }
        .sheet(isPresented: $showingChapters) {
            if let book = player.currentBook { ChaptersSheet(book: book) }
        }
    }

    // MARK: - Loaded state

    private func content(for book: Book) -> some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 0) {
                    CoverArtView(book: book, size: 240, cornerRadius: Theme.Radius.coverLarge)
                        .padding(.top, 28)
                        .padding(.bottom, 22)

                    Text(book.title)
                        .font(.serif(20, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                        .padding(.horizontal, Theme.Spacing.lg)

                    if let author = book.author {
                        Text(author)
                            .font(.ui(13))
                            .foregroundStyle(Theme.Colors.dInkSoft)
                            .padding(.top, 4)
                    }

                    ScrubberView(
                        currentTime: $player.currentTime,
                        duration: player.duration
                    ) { newTime in
                        player.seek(to: newTime)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, 24)

                    PlayerControlsRow()

                    PlayerSecondaryRow(
                        showingSpeedSheet: $showingSpeedSheet,
                        showingSleepSheet: $showingSleepSheet,
                        showingBookmarks: $showingBookmarks,
                        showingChapters: $showingChapters,
                        hasChapters: !book.chaptersArray.isEmpty
                    )
                    .padding(.bottom, 20)
                }
            }
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "headphones")
                .font(.system(size: 40, weight: .regular))
                .foregroundStyle(Theme.Colors.dInkMute)
            Text("Nothing playing")
                .font(.ui(15, weight: .semibold))
                .foregroundStyle(Theme.Colors.dInkSoft)
            Text("Pick a book from your library to start listening.")
                .font(.ui(12.5))
                .foregroundStyle(Theme.Colors.dInkMute)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
    }
}
#endif
