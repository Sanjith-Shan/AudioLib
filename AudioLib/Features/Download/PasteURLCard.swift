import SwiftUI

struct PasteURLCard: View {
    @Binding var urlText: String
    @Binding var isDownloading: Bool
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text("Add Audiobook")
                .font(.titleLg)
                .foregroundStyle(Theme.Colors.white)

            // Use a custom text field variant that looks good on the dark card background
            DarkFlatTextField(
                text: $urlText,
                placeholder: "Paste YouTube URL"
            )

            HStack {
                PillButton(
                    title: isDownloading ? "Downloading..." : "Download",
                    style: .primary
                ) {
                    onDownload()
                }
                .disabled(urlText.isEmpty || isDownloading)
                .opacity(urlText.isEmpty || isDownloading ? 0.5 : 1.0)

                Spacer()
            }
        }
        .padding(Theme.Spacing.lg)
        .background(Theme.Colors.dark)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

/// A text field styled for use on dark backgrounds (dark card surface).
private struct DarkFlatTextField: View {
    @Binding var text: String
    let placeholder: String

    var body: some View {
        TextField(placeholder, text: $text)
            .font(.bodyRegular)
            .foregroundStyle(Theme.Colors.dark)
            .keyboardType(.URL)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .padding(.vertical, Theme.Spacing.sm + Theme.Spacing.xs)
            .padding(.horizontal, Theme.Spacing.md)
            .background(Theme.Colors.white)
            .clipShape(Capsule())
    }
}

#Preview {
    @Previewable @State var urlText = ""
    @Previewable @State var isDownloading = false
    PasteURLCard(urlText: $urlText, isDownloading: $isDownloading) {}
        .padding()
        .background(Theme.Colors.surface)
}
