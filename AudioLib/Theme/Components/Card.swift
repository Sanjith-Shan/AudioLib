import SwiftUI

/// Applies 20px radius, surface background, 16pt padding, no shadow.
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.Spacing.md)
            .background(Theme.Colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}

#Preview {
    Text("Card content")
        .cardStyle()
        .padding()
}
