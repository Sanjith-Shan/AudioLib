import SwiftUI

struct LibraryTabView: View {
    var body: some View {
        NavigationStack {
            EmptyStateView(
                iconName: "books.vertical.fill",
                title: "Your Library",
                subtitle: "Downloaded books will appear here"
            )
            .navigationTitle("Library")
            .background(Theme.Colors.white)
        }
    }
}

#Preview {
    LibraryTabView()
}
