import SwiftUI

struct PlayerSecondaryRow: View {
    @Binding var showingSpeedSheet: Bool
    @Binding var showingSleepSheet: Bool
    @Binding var showingBookmarks: Bool
    @Binding var showingChapters: Bool
    let hasChapters: Bool

    @State private var player = PlayerController.shared

    var body: some View {
        HStack(alignment: .top) {
            secondaryButton(label: "Speed", active: false) {
                showingSpeedSheet = true
            } icon: {
                Text("\(speedLabel)×")
                    .font(.ui(14, weight: .bold))
            }

            Spacer()

            sleepButton

            Spacer()

            if hasChapters {
                secondaryButton(label: "Chapters", active: false) {
                    showingChapters = true
                } icon: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 20, weight: .regular))
                }
                Spacer()
            }

            secondaryButton(label: "Marks", active: false) {
                showingBookmarks = true
            } icon: {
                Image(systemName: "bookmark")
                    .font(.system(size: 18, weight: .regular))
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.bottom, 36)
    }

    // Sleep timer button with live countdown.
    private var sleepButton: some View {
        TimelineView(.periodic(from: .now, by: 1)) { _ in
            let active = player.isSleepTimerActive
            let label = active ? countdownLabel : "Sleep"
            secondaryButton(label: label, active: active) {
                showingSleepSheet = true
            } icon: {
                Image(systemName: active ? "moon.fill" : "moon")
                    .font(.system(size: 18, weight: .regular))
            }
        }
    }

    @ViewBuilder
    private func secondaryButton<Icon: View>(
        label: String,
        active: Bool,
        action: @escaping () -> Void,
        @ViewBuilder icon: () -> Icon
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                icon()
                    .foregroundStyle(active ? Theme.Colors.teal : Theme.Colors.dInkSoft)
                    .frame(width: 44, height: 32)
                    .background(active ? Theme.Colors.teal.opacity(0.2) : Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text(label)
                    .font(.mono(10.5))
                    .foregroundStyle(active ? Theme.Colors.teal : Theme.Colors.dInkMute)
            }
            .frame(minWidth: 56)
        }
        .buttonStyle(.plain)
    }

    private var speedLabel: String {
        let rate = player.playbackRate
        if rate == Float(Int(rate)) { return "\(Int(rate))" }
        return String(format: "%g", rate)
    }

    private var countdownLabel: String {
        guard let end = player.sleepTimerEndDate else { return "Sleep" }
        let remaining = max(0, Int(end.timeIntervalSinceNow))
        return String(format: "%d:%02d", remaining / 60, remaining % 60)
    }
}
