import SwiftUI

struct SleepTimerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var player = PlayerController.shared
    @State private var customMinutes: String = ""
    @State private var customError: String? = nil
    @FocusState private var customFocused: Bool

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
        VStack(spacing: 0) {
            DarkSheetHeader(title: "Sleep Timer") { dismiss() }

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    VStack(spacing: 0) {
                        ForEach(Array(options.enumerated()), id: \.element.id) { index, option in
                            Button {
                                player.setSleepTimer(seconds: option.seconds)
                                if option.seconds != nil { Haptics.success() }
                                dismiss()
                            } label: {
                                HStack {
                                    Text(option.label)
                                        .font(.ui(16))
                                        .foregroundStyle(.white)
                                    Spacer()
                                    if isSelected(option) {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 15, weight: .bold))
                                            .foregroundStyle(Theme.Colors.teal)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)
                            }
                            .buttonStyle(.plain)

                            if index < options.count - 1 {
                                Rectangle().fill(Color.white.opacity(0.08)).frame(height: 0.5)
                                    .padding(.leading, 16)
                            }
                        }
                    }
                    .background(Theme.Colors.dSheetRow)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text("CUSTOM")
                        .font(.ui(11, weight: .bold))
                        .tracking(0.5)
                        .foregroundStyle(Theme.Colors.dInkSoft)
                        .padding(.horizontal, 6)
                        .padding(.top, 18)
                        .padding(.bottom, 8)

                    HStack(spacing: 10) {
                        TextField("", text: $customMinutes, prompt: Text("20").foregroundColor(Theme.Colors.dInkMute))
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                            .focused($customFocused)
                            .font(.mono(16))
                            .foregroundStyle(.white)
                        Text("minutes")
                            .font(.ui(14))
                            .foregroundStyle(Theme.Colors.dInkSoft)
                        Button("Set") { applyCustom() }
                            .font(.ui(14, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(isCustomValid ? Theme.Colors.teal : Color.white.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .disabled(!isCustomValid)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Theme.Colors.dSheetRow)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                    Text(customError ?? "1–999 min")
                        .font(.ui(12))
                        .foregroundStyle(customError == nil ? Theme.Colors.dInkMute : Theme.Colors.red)
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Theme.Colors.dSheet.ignoresSafeArea())
        .preferredColorScheme(.dark)
        #if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.Colors.dSheet)
        #endif
    }

    private var isCustomValid: Bool {
        let trimmed = customMinutes.trimmingCharacters(in: .whitespaces)
        guard let minutes = Int(trimmed) else { return false }
        return (1...999).contains(minutes)
    }

    private func applyCustom() {
        let trimmed = customMinutes.trimmingCharacters(in: .whitespaces)
        guard let minutes = Int(trimmed), (1...999).contains(minutes) else {
            customError = "Enter a number between 1 and 999"
            Haptics.warning()
            return
        }
        customError = nil
        player.setSleepTimer(seconds: Double(minutes) * 60)
        Haptics.success()
        dismiss()
    }

    private func isSelected(_ option: TimerOption) -> Bool {
        if option.seconds == nil { return !player.isSleepTimerActive }
        guard player.isSleepTimerActive, let end = player.sleepTimerEndDate else { return false }
        let remaining = end.timeIntervalSinceNow
        return abs(remaining - (option.seconds ?? 0)) < 60
    }
}
