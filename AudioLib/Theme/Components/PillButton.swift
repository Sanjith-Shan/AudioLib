import SwiftUI

enum PillButtonStyle {
    case primary    // ink bg, paper text — light-context CTA
    case teal       // teal bg, white text — dark-context CTA
    case secondary  // cardSoft bg, ink text
    case danger
    case ghost
}

struct PillButton: View {
    let title: String
    let style: PillButtonStyle
    let action: () -> Void

    private var backgroundColor: Color {
        switch style {
        case .primary:   return Theme.Colors.ink
        case .teal:      return Theme.Colors.teal
        case .secondary: return Theme.Colors.cardSoft
        case .danger:    return Theme.Colors.red
        case .ghost:     return Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:   return Theme.Colors.paperFg
        case .teal:      return .white
        case .secondary: return Theme.Colors.ink
        case .danger:    return .white
        case .ghost:     return Theme.Colors.ink
        }
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.ui(15, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .padding(.vertical, Theme.Button.paddingV)
                .padding(.horizontal, Theme.Button.paddingH)
                .background(backgroundColor)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.button, style: .continuous))
                .overlay(
                    style == .ghost
                        ? RoundedRectangle(cornerRadius: Theme.Radius.button).stroke(Theme.Colors.ink, lineWidth: 1.5)
                        : nil
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        PillButton(title: "Primary", style: .primary) {}
        PillButton(title: "Teal", style: .teal) {}
        PillButton(title: "Secondary", style: .secondary) {}
        PillButton(title: "Danger", style: .danger) {}
    }
    .padding()
    .background(Theme.Colors.paper)
}
