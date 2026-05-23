import SwiftUI

struct EmptyStateView: View {
    let iconName: String
    let title: String
    let subtitle: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    /// Size of the soft rounded icon container.
    var circleSize: CGFloat = 84

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                RoundedRectangle(cornerRadius: circleSize * 0.29, style: .continuous)
                    .fill(Theme.Colors.cardSoft)
                    .frame(width: circleSize, height: circleSize)
                Image(systemName: iconName)
                    .font(.system(size: circleSize * 0.47, weight: .light))
                    .foregroundStyle(Theme.Colors.inkMute)
            }
            .padding(.bottom, 18)

            Text(title)
                .font(.serif(19, weight: .bold))
                .foregroundStyle(Theme.Colors.ink)
                .multilineTextAlignment(.center)

            Text(subtitle)
                .font(.ui(14))
                .foregroundStyle(Theme.Colors.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.top, 6)
                .frame(maxWidth: 260)

            if let actionTitle, let action {
                PillButton(title: actionTitle, style: .primary, action: action)
                    .padding(.top, 22)
            }
        }
        .padding(.horizontal, Theme.Spacing.xl)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

#Preview {
    EmptyStateView(
        iconName: "books.vertical.fill",
        title: "Your Library",
        subtitle: "Downloaded audiobooks will appear here.",
        actionTitle: "Download one",
        action: {}
    )
    .background(Theme.Colors.paper)
}
