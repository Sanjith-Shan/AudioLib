import SwiftUI

struct OnboardingSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: Theme.Spacing.xl) {
            Spacer()

            Image(systemName: "headphones")
                .font(.system(size: 64))
                .foregroundStyle(Theme.Colors.blue)

            VStack(spacing: Theme.Spacing.sm) {
                Text("AudioLib")
                    .font(.displayLg)
                    .foregroundStyle(Theme.Colors.dark)

                Text("Download YouTube audiobooks and listen offline. Paste any YouTube link in the Download tab to get started.")
                    .font(.bodyRegular)
                    .foregroundStyle(Theme.Colors.midSlate)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.xl)
            }

            Spacer()

            PillButton(title: "Get Started", style: .primary) {
                LocalNotifications.requestPermission()
                dismiss()
            }
            .padding(.horizontal, Theme.Spacing.xl)
            .padding(.bottom, Theme.Spacing.xl)
        }
        .background(Theme.Colors.white)
        .interactiveDismissDisabled(true)
    }
}
