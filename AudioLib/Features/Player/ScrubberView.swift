import SwiftUI

struct ScrubberView: View {
    @Binding var currentTime: Double
    let duration: Double
    let onSeek: (Double) -> Void

    @State private var isDragging = false
    @State private var dragTime: Double = 0

    private var displayTime: Double { isDragging ? dragTime : currentTime }

    var body: some View {
        VStack(spacing: Theme.Spacing.xs) {
            Slider(
                value: Binding(
                    get: { isDragging ? (duration > 0 ? dragTime / duration : 0) : (duration > 0 ? currentTime / duration : 0) },
                    set: { newValue in
                        isDragging = true
                        dragTime = newValue * duration
                    }
                ),
                in: 0...1,
                onEditingChanged: { editing in
                    if !editing {
                        onSeek(dragTime)
                        isDragging = false
                    }
                }
            )
            .tint(Theme.Colors.teal)

            HStack {
                Text(DurationFormatter.format(seconds: displayTime))
                    .font(.captionSmall)
                    .foregroundStyle(Theme.Colors.white.opacity(0.6))
                Spacer()
                Text("-\(DurationFormatter.format(seconds: max(0, duration - displayTime)))")
                    .font(.captionSmall)
                    .foregroundStyle(Theme.Colors.white.opacity(0.6))
            }
        }
    }
}
