import SwiftUI

struct PlayerControlsRow: View {
    @State private var player = PlayerController.shared
    @AppStorage("audiolib.defaultSkipInterval") private var skipInterval: Double = 15

    var body: some View {
        HStack {
            Button { player.skipBackward() } label: {
                Image(systemName: skipSymbol(forward: false))
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip back \(Int(skipInterval)) seconds")

            Spacer()

            Button { player.togglePlayPause() } label: {
                Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(Theme.Colors.ink)
                    .frame(width: 72, height: 72)
                    .background(Color.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.35), radius: 20, y: 6)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(player.isPlaying ? "Pause" : "Play")

            Spacer()

            Button { player.skipForward() } label: {
                Image(systemName: skipSymbol(forward: true))
                    .font(.system(size: 30, weight: .regular))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Skip forward \(Int(skipInterval)) seconds")
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, 12)
        .padding(.bottom, Theme.Spacing.lg)
    }

    private func skipSymbol(forward: Bool) -> String {
        let supported = [5, 10, 15, 30, 45, 60, 75, 90]
        let prefix = forward ? "goforward" : "gobackward"
        return supported.contains(Int(skipInterval)) ? "\(prefix).\(Int(skipInterval))" : prefix
    }
}
