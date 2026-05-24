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
    @State private var showingEditSheet = false

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 0) {
                        CoverArtView(
                            book: book,
                            size: coverSize(for: geo.size.width),
                            cornerRadius: Theme.Radius.coverLarge
                        )
                        .padding(.top, Theme.Spacing.lg)
                        .padding(.bottom, 20)

                        // Title + author
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(book.title)
                                    .font(.serif(24, weight: .bold))
                                    .foregroundStyle(.white)
                                    .lineLimit(2)
                                if let author = book.author {
                                    Text(author)
                                        .font(.ui(14.5))
                                        .foregroundStyle(Theme.Colors.dInkSoft)
                                }
                            }
                            Spacer(minLength: 12)
                            Button { showingBookmarks = true } label: {
                                Image(systemName: "bookmark")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Theme.Colors.dInkSoft)
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Bookmarks")
                        }
                        .padding(.horizontal, Theme.Spacing.lg)

                        ScrubberView(
                            currentTime: $player.currentTime,
                            duration: player.duration
                        ) { newTime in
                            player.seek(to: newTime)
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.top, Theme.Spacing.lg)

                        PlayerControlsRow()

                        PlayerSecondaryRow(
                            showingSpeedSheet: $showingSpeedSheet,
                            showingSleepSheet: $showingSleepSheet,
                            showingBookmarks: $showingBookmarks,
                            showingChapters: $showingChapters,
                            hasChapters: !book.chaptersArray.isEmpty
                        )
                    }
                }
            }
        }
        .background(Theme.Gradients.player.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingSpeedSheet) { SpeedSheet() }
        .sheet(isPresented: $showingSleepSheet) { SleepTimerSheet() }
        .sheet(isPresented: $showingBookmarks) { BookmarksSheet(book: book) }
        .sheet(isPresented: $showingChapters) { ChaptersSheet(book: book) }
        .sheet(isPresented: $showingEditSheet) { BookEditSheet(book: book) }
        .onAppear {
            if player.currentBook?.id != book.id {
                player.load(book: book)
            }
            player.play()
        }
    }

    // MARK: - Custom nav header

    private var header: some View {
        HStack {
            glassButton("chevron.down", label: "Close player") {
                router.showingPlayer = false
            }
            Spacer()
            VStack(spacing: 1) {
                Text("PLAYING FROM LIBRARY")
                    .font(.ui(11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.Colors.dInkSoft)
                Text(book.title)
                    .font(.ui(13, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            Spacer()
            glassButton("ellipsis", label: "Edit book") {
                showingEditSheet = true
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, 10)
    }

    private func glassButton(_ symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(Color.white.opacity(0.12))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func coverSize(for containerWidth: CGFloat) -> CGFloat {
        let target = containerWidth - Theme.Spacing.xl * 2
        return max(200, min(target, 320))
    }
}
