import SwiftUI

struct OnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss

    private struct Feature: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let subtitle: String
    }

    private let features: [Feature] = [
        Feature(icon: "arrow.down.circle", title: "Download from YouTube", subtitle: "Paste a link, get an audiobook."),
        Feature(icon: "books.vertical", title: "A real library", subtitle: "Continue listening, sorted your way."),
        Feature(icon: "note.text", title: "Take notes with timestamps", subtitle: "Bookmark thoughts as you listen."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer().frame(height: 80)

            // App icon
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Theme.Gradients.appIcon)
                    .frame(width: 112, height: 112)
                    .shadow(color: Color(hex: 0x0F5751, opacity: 0.32), radius: 20, y: 16)
                Image(systemName: "headphones")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(Theme.Colors.paperFg)
            }
            .padding(.bottom, 32)

            Text("AudioLib")
                .font(.serif(40, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
                .padding(.bottom, 10)

            Text("Turn any YouTube link into an audiobook you actually own.")
                .font(.ui(17))
                .foregroundStyle(Theme.Colors.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 280)

            Spacer(minLength: 32)

            VStack(spacing: 18) {
                ForEach(features) { f in
                    HStack(spacing: 14) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.Colors.tealSoft)
                                .frame(width: 36, height: 36)
                            Image(systemName: f.icon)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(Theme.Colors.tealInk)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text(f.title)
                                .font(.ui(15, weight: .semibold))
                                .foregroundStyle(Theme.Colors.ink)
                            Text(f.subtitle)
                                .font(.ui(13))
                                .foregroundStyle(Theme.Colors.inkSoft)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.bottom, 36)

            Button {
                LocalNotifications.requestPermission()
                dismiss()
            } label: {
                Text("Get Started")
                    .font(.ui(17, weight: .semibold))
                    .foregroundStyle(Theme.Colors.paperFg)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Theme.Colors.ink)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: Color(hex: 0x1B1814, opacity: 0.22), radius: 16, y: 4)
            }
            .buttonStyle(.plain)

            Text("We'll ask for notifications next so we can tell you when downloads finish.")
                .font(.ui(12))
                .foregroundStyle(Theme.Colors.inkMute)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Gradients.onboarding.ignoresSafeArea())
        .interactiveDismissDisabled(true)
    }
}
