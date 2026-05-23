import SwiftUI

struct ScrubberView: View {
    @Binding var currentTime: Double
    let duration: Double
    let onSeek: (Double) -> Void

    @State private var isDragging = false
    @State private var dragTime: Double = 0

    private var displayTime: Double { isDragging ? dragTime : currentTime }

    var body: some View {
        VStack(spacing: 6) {
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
            .tint(.white)

            HStack {
                Text(DurationFormatter.format(seconds: displayTime))
                Spacer()
                Text("-\(DurationFormatter.format(seconds: max(0, duration - displayTime)))")
            }
            .font(.mono(11))
            .foregroundStyle(Theme.Colors.dInkMute)
        }
    }
}
