import SwiftUI

struct SpeedSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var player = PlayerController.shared

    let speeds: [Float] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]

    var body: some View {
        VStack(spacing: 0) {
            DarkSheetHeader(title: "Playback Speed") { dismiss() }

            ScrollView {
                VStack(spacing: 0) {
                    Text("Adjust how fast the narrator reads.")
                        .font(.ui(13))
                        .foregroundStyle(Theme.Colors.dInkSoft)
                        .padding(.bottom, 16)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(speeds, id: \.self) { speed in
                            let isActive = player.playbackRate == speed
                            Button {
                                player.setRate(speed)
                                dismiss()
                            } label: {
                                Text(label(for: speed))
                                    .font(.ui(18, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(1.1, contentMode: .fit)
                                    .background(isActive ? Theme.Colors.teal : Color.white.opacity(0.06))
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        isActive ? nil :
                                        RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                    .shadow(color: isActive ? Theme.Colors.teal.opacity(0.4) : .clear, radius: 14, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    (Text("Speed changes apply instantly to all books. Most listeners settle at ")
                        + Text("1.5×").foregroundColor(.white).bold())
                        .font(.ui(12.5))
                        .foregroundStyle(Theme.Colors.dInkSoft)
                        .lineSpacing(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(14)
                        .background(Color.white.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .padding(.top, 18)
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

    private func label(for speed: Float) -> String {
        speed == Float(Int(speed)) ? "\(Int(speed)).0×" : "\(speed)×"
    }
}

/// Centered title with a trailing teal "Done" button, for dark modal sheets.
struct DarkSheetHeader: View {
    let title: String
    var leading: String? = nil
    var leadingAction: (() -> Void)? = nil
    let onDone: () -> Void

    var body: some View {
        ZStack {
            Text(title)
                .font(.ui(16, weight: .semibold))
                .foregroundStyle(.white)

            HStack {
                if let leading, let leadingAction {
                    Button(leading, action: leadingAction)
                        .font(.ui(16))
                        .foregroundStyle(Theme.Colors.dInkSoft)
                }
                Spacer()
                Button("Done", action: onDone)
                    .font(.ui(16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.teal)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 12)
    }
}
