import SwiftUI

struct SpeedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var player = PlayerController.shared

    let speeds: [Float] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                Text("Playback Speed")
                    .font(.titleLg)
                    .foregroundStyle(Theme.Colors.dark)
                    .padding(.top)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: Theme.Spacing.sm) {
                    ForEach(speeds, id: \.self) { speed in
                        Button {
                            player.setRate(speed)
                            dismiss()
                        } label: {
                            let label = speed == Float(Int(speed)) ? "\(Int(speed))x" : "\(speed)x"
                            Text(label)
                                .font(.bodySemibold)
                                .foregroundStyle(player.playbackRate == speed ? Theme.Colors.white : Theme.Colors.dark)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, Theme.Spacing.md)
                                .background(player.playbackRate == speed ? Theme.Colors.blue : Theme.Colors.surface)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .background(Theme.Colors.white)
            .presentationDetents([.medium])
        }
    }
}
