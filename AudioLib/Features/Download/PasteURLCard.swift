import SwiftUI

struct PasteURLCard: View {
    @Binding var urlText: String
    @Binding var isDownloading: Bool
    let onDownload: () -> Void

    private var canDownload: Bool { !urlText.isEmpty && !isDownloading }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("ADD AUDIOBOOK")
                .font(.ui(11, weight: .bold))
                .tracking(0.8)
                .foregroundStyle(Theme.Colors.paperFg.opacity(0.55))
                .padding(.bottom, 6)

            Text("Paste a YouTube link")
                .font(.ui(22, weight: .bold))
                .foregroundStyle(Theme.Colors.paperFg)
                .padding(.bottom, 14)

            // URL field
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.paperFg.opacity(0.5))
                TextField(
                    "",
                    text: $urlText,
                    prompt: Text("youtube.com/watch?v=…")
                        .foregroundColor(Theme.Colors.paperFg.opacity(0.35))
                )
                .font(.mono(14.5))
                .foregroundStyle(Theme.Colors.paperFg)
                #if os(iOS)
                .keyboardType(.URL)
                .textInputAutocapitalization(.never)
                #endif
                .autocorrectionDisabled()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.field)
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
            )

            // Download button
            Button(action: onDownload) {
                HStack(spacing: 8) {
                    if isDownloading {
                        ProgressView()
                            .controlSize(.small)
                            .tint(Theme.Colors.ink)
                        Text("Downloading…")
                    } else {
                        Text("Download")
                    }
                }
                .font(.ui(16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .background(canDownload ? Theme.Colors.paperFg : Color.white.opacity(0.18))
                .foregroundStyle(canDownload ? Theme.Colors.ink : Theme.Colors.paperFg.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.field, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(!canDownload)
            .padding(.top, 12)
        }
        .padding(.horizontal, 18)
        .padding(.top, 18)
        .padding(.bottom, 16)
        .background(Theme.Colors.ink)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.cardLarge, style: .continuous))
        .shadow(color: Color(hex: 0x1B1814, opacity: 0.18), radius: 24, y: 6)
    }
}
