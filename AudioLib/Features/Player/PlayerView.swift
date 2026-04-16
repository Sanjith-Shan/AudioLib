import SwiftUI

struct PlayerView: View {
    let book: Book
    @Environment(\.dismiss) private var dismiss
    @Environment(AppRouter.self) private var router
    @State private var player = PlayerController.shared

    @State private var showingSpeedSheet = false
    @State private var showingSleepSheet = false
    @State private var showingBookmarks = false
    @State private var showingChapters = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.xl) {
                    // Large cover art
                    CoverArtView(book: book, size: coverSize, cornerRadius: Theme.Radius.card)
                        .padding(.top, Theme.Spacing.lg)

                    // Title + author
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(book.title)
                            .font(.titleLg)
                            .foregroundStyle(Theme.Colors.white)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)

                        if let author = book.author {
                            Text(author)
                                .font(.bodyRegular)
                                .foregroundStyle(Theme.Colors.white.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Scrubber
                    ScrubberView(
                        currentTime: $player.currentTime,
                        duration: player.duration
                    ) { newTime in
                        player.seek(to: newTime)
                    }
                    .padding(.horizontal, Theme.Spacing.lg)

                    // Main controls
                    PlayerControlsRow()

                    // Secondary controls
                    PlayerSecondaryRow(
                        showingSpeedSheet: $showingSpeedSheet,
                        showingSleepSheet: $showingSleepSheet,
                        showingBookmarks: $showingBookmarks,
                        showingChapters: $showingChapters,
                        hasChapters: !book.chaptersArray.isEmpty
                    )
                }
            }
            .background(Theme.Colors.dark)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        router.showingPlayer = false
                    } label: {
                        Image(systemName: "chevron.down")
                            .foregroundStyle(Theme.Colors.white)
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        // Book edit sheet — future
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundStyle(Theme.Colors.white)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSpeedSheet) { SpeedSheet() }
        .sheet(isPresented: $showingSleepSheet) { SleepTimerSheet() }
        .sheet(isPresented: $showingBookmarks) { BookmarksSheet(book: book) }
        .sheet(isPresented: $showingChapters) { ChaptersSheet(book: book) }
        .onAppear {
            if player.currentBook?.id != book.id {
                player.load(book: book)
            }
            player.play()
        }
    }

    private var coverSize: CGFloat {
        UIScreen.main.bounds.width - Theme.Spacing.xl * 2
    }
}
