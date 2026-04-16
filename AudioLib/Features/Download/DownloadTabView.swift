import SwiftUI

struct DownloadTabView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: Theme.Spacing.md) {
                PasteURLCard()
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)

                EmptyStateView(
                    iconName: "arrow.down.circle.fill",
                    title: "Download Audiobooks",
                    subtitle: "Paste a YouTube link to download"
                )
            }
            .navigationTitle("Download")
            .background(Theme.Colors.white)
        }
    }
}

#Preview {
    DownloadTabView()
}
