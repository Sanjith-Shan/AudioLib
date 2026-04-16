import SwiftUI

/// A dark card with a URL input field and download button.
struct PasteURLCard: View {
    @State private var urlText: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Add Audiobook")
                .font(.titleLg)
                .foregroundStyle(Theme.Colors.white)

            FlatTextField(
                placeholder: "Paste YouTube URL",
                text: $urlText,
                keyboardType: .URL
            )

            PillButton(title: "Download", style: .primary) {
                // Phase 3: will trigger DownloadManager
            }
        }
        .padding(Theme.Spacing.md)
        .background(Theme.Colors.dark)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

#Preview {
    PasteURLCard()
        .padding()
}
