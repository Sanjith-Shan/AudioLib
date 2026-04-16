import SwiftUI

struct PlayerControlsRow: View {
    @State private var player = PlayerController.shared
    @AppStorage("audiolib.defaultSkipInterval") private var skipInterval: Double = 15

    var body: some View {
        HStack(spacing: Theme.Spacing.xxl) {
            // Skip backward
            Button { player.skipBackward() } label: {
                Image(systemName: skipSymbol(forward: false))
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

            // Skip forward
            Button { player.skipForward() } label: {
                Image(systemName: skipSymbol(forward: true))
                    .font(.system(size: 28))
                    .foregroundStyle(Theme.Colors.white)
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)
        }
    }

    private func skipSymbol(forward: Bool) -> String {
        let supported = [10, 15, 30, 45, 60, 75, 90]
        let prefix = forward ? "goforward" : "gobackward"
        return supported.contains(Int(skipInterval)) ? "\(prefix).\(Int(skipInterval))" : prefix
    }
}
