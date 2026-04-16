import SwiftUI

enum PillButtonStyle {
    case primary
    case secondary
    case danger
    case ghost
}

struct PillButton: View {
    let title: String
    let style: PillButtonStyle
    let action: () -> Void

    private var backgroundColor: Color {
        switch style {
        case .primary:   return Theme.Colors.dark
        case .secondary: return Theme.Colors.surface
        case .danger:    return Theme.Colors.danger
        case .ghost:     return Color.clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary:   return Theme.Colors.white
        case .secondary: return Theme.Colors.dark
        case .danger:    return Theme.Colors.white
        case .ghost:     return Theme.Colors.dark
        }
    }

    private var hasBorder: Bool {
        style == .ghost
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.bodySemibold)
                .foregroundStyle(foregroundColor)
                .padding(.vertical, Theme.Button.paddingV)
                .padding(.horizontal, Theme.Button.paddingH)
                .background(backgroundColor)
                .clipShape(Capsule())
                .overlay(
                    hasBorder
                        ? Capsule().stroke(Theme.Colors.dark, lineWidth: 2)
                        : nil
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: Theme.Spacing.md) {
        PillButton(title: "Primary", style: .primary) {}
        PillButton(title: "Secondary", style: .secondary) {}
        PillButton(title: "Danger", style: .danger) {}
        PillButton(title: "Ghost", style: .ghost) {}
    }
    .padding()
}
