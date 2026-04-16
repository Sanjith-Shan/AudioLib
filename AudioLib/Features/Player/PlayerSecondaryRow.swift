import SwiftUI

struct PlayerSecondaryRow: View {
    @Binding var showingSpeedSheet: Bool
    @Binding var showingSleepSheet: Bool
    @Binding var showingBookmarks: Bool
    @Binding var showingChapters: Bool
    let hasChapters: Bool

    @State private var player = PlayerController.shared

    var body: some View {
        HStack(spacing: Theme.Spacing.xl) {
            // Speed
            Button {
                showingSpeedSheet = true
            } label: {
                Text("\(speedLabel)x")
                    .font(.bodySemibold)
                    .foregroundStyle(Theme.Colors.white)
                    .frame(width: 48, height: 32)
                    .background(Theme.Colors.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardSmall))
            }
            .buttonStyle(.plain)

            // Sleep timer
            Button { showingSleepSheet = true } label: {
                Image(systemName: player.isSleepTimerActive ? "moon.fill" : "moon")
                    .font(.system(size: 22))
                    .foregroundStyle(player.isSleepTimerActive ? Theme.Colors.teal : Theme.Colors.white)
            }
            .buttonStyle(.plain)

            // Bookmark
            Button { player.addBookmark() } label: {
                Image(systemName: "bookmark")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.Colors.white)
            }
            .buttonStyle(.plain)

            // Chapters (only if available)
            if hasChapters {
                Button { showingChapters = true } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 22))
                        .foregroundStyle(Theme.Colors.white)
                }
                .buttonStyle(.plain)
            }

            // All bookmarks
            Button { showingBookmarks = true } label: {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.Colors.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var speedLabel: String {
        let rate = player.playbackRate
        if rate == Float(Int(rate)) { return "\(Int(rate))" }
        return String(format: "%.2g", rate)
    }
}
