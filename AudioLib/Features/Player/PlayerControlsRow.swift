import SwiftUI

struct PlayerControlsRow: View {
    @State private var player = PlayerController.shared

    var body: some View {
        HStack(spacing: Theme.Spacing.xxl) {
            // Skip back 15s
            Button { player.skipBackward() } label: {
                Image(systemName: "gobackward.15")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.white)
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)

            // Play/pause (72pt blue circle)
            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Theme.Colors.white)
                    .frame(width: 72, height: 72)
                    .background(Theme.Colors.blue)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)

            // Skip forward 15s
            Button { player.skipForward() } label: {
                Image(systemName: "goforward.15")
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.white)
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)
        }
    }
}
