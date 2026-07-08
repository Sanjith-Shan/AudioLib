import SwiftUI

/// In-app volume control that can boost audio *beyond* the iPhone's hardware
/// maximum. 100% is unity; above that the audio engine applies real gain so
/// quiet audiobooks stay audible even at full system volume.
struct VolumeBoostRow: View {
    @State private var player = PlayerController.shared

    private var percent: Int { Int((player.volumeBoost * 100).rounded()) }
    private var isBoosted: Bool { player.volumeBoost > 1.001 }

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.dInkMute)
                    .frame(width: 18)

                Slider(
                    value: Binding(
                        get: { Double(player.volumeBoost) },
                        set: { player.volumeBoost = Float($0) }
                    ),
                    in: 0...Double(PlayerController.maxVolumeBoost)
                )
                .tint(isBoosted ? Theme.Colors.teal : .white)

                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(isBoosted ? Theme.Colors.teal : Theme.Colors.dInkMute)
                    .frame(width: 18)
            }

            HStack {
                Text("VOLUME")
                    .font(.ui(11, weight: .semibold))
                    .tracking(0.6)
                    .foregroundStyle(Theme.Colors.dInkMute)
                Spacer()
                Text("\(percent)%")
                    .font(.mono(11))
                    .foregroundStyle(isBoosted ? Theme.Colors.teal : Theme.Colors.dInkMute)
                    + Text(isBoosted ? "  BOOST" : "")
                    .font(.mono(11))
                    .foregroundStyle(Theme.Colors.teal)
            }
        }
    }
}
