import SwiftUI

struct SleepTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var player = PlayerController.shared

    struct TimerOption: Identifiable {
        let id = UUID()
        let label: String
        let seconds: Double?
    }

    let options: [TimerOption] = [
        TimerOption(label: "Off", seconds: nil),
        TimerOption(label: "5 min", seconds: 300),
        TimerOption(label: "10 min", seconds: 600),
        TimerOption(label: "15 min", seconds: 900),
        TimerOption(label: "30 min", seconds: 1800),
        TimerOption(label: "45 min", seconds: 2700),
        TimerOption(label: "1 hour", seconds: 3600),
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                Text("Sleep Timer")
                    .font(.titleLg)
                    .foregroundStyle(Theme.Colors.dark)
                    .padding(.top)

                ForEach(options) { option in
                    Button {
                        player.setSleepTimer(seconds: option.seconds)
                        dismiss()
                    } label: {
                        HStack {
                            Text(option.label)
                                .font(.bodyRegular)
                                .foregroundStyle(Theme.Colors.dark)
                            Spacer()
                            if isSelected(option) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Theme.Colors.blue)
                            }
                        }
                        .padding(.horizontal, Theme.Spacing.lg)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(isSelected(option) ? Theme.Colors.surface : Theme.Colors.white)
                    }
                    .buttonStyle(.plain)

                    Divider().padding(.horizontal)
                }

                Spacer()
            }
            .background(Theme.Colors.white)
            .presentationDetents([.medium])
        }
    }

    private func isSelected(_ option: TimerOption) -> Bool {
        if option.seconds == nil { return !player.isSleepTimerActive }
        guard player.isSleepTimerActive, let end = player.sleepTimerEndDate else { return false }
        let remaining = end.timeIntervalSinceNow
        return abs(remaining - (option.seconds ?? 0)) < 60
    }
}
