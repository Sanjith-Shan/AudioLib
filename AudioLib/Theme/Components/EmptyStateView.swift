import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Image(systemName: iconName)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Theme.Colors.coolGray)

            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(.titleMd)
                    .foregroundStyle(Theme.Colors.dark)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.bodyRegular)
                    .foregroundStyle(Theme.Colors.midSlate)
                    .multilineTextAlignment(.center)
            }

            if let actionTitle, let action {
                PillButton(title: actionTitle, style: .primary, action: action)
                    .padding(.top, Theme.Spacing.sm)
            }
        }
        .padding(Theme.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        iconName: "books.vertical.fill",
        title: "Your Library",
        subtitle: "Downloaded books will appear here",
        actionTitle: "Download a book",
        action: {}
    )
}
