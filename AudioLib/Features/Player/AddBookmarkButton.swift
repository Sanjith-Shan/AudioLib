import SwiftUI

struct AddBookmarkButton: View {
    let action: () -> Void
    @State private var justAdded = false

    var body: some View {
        Button {
            action()
            withAnimation(.easeInOut(duration: 0.18)) { justAdded = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation(.easeInOut(duration: 0.18)) { justAdded = false }
            }
        } label: {
            HStack(spacing: Theme.Spacing.sm) {
                Image(systemName: justAdded ? "checkmark.circle.fill" : "bookmark.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text(justAdded ? "Bookmark added" : "Bookmark this position")
                    .font(.bodySemibold)
                Spacer()
            }
            .foregroundStyle(Theme.Colors.white)
            .padding(.vertical, Theme.Spacing.md)
            .padding(.horizontal, Theme.Spacing.md)
            .background(justAdded ? Theme.Colors.teal : Theme.Colors.blue)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardSmall))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(justAdded ? "Bookmark added" : "Bookmark this position")
    }
}
