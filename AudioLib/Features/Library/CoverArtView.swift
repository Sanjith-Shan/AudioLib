import SwiftUI

struct CoverArtView: View {
    let book: Book
    let size: CGFloat
    var cornerRadius: CGFloat = Theme.Radius.cardSmall

    var body: some View {
        Group {
            if let artURL = book.artURL,
               FileManager.default.fileExists(atPath: artURL.path),
               let uiImage = UIImage(contentsOfFile: artURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                LinearGradient(
                    colors: gradientColors(for: book.id),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .overlay(
                    Image(systemName: "headphones")
                        .font(.system(size: size * 0.35))
                        .foregroundStyle(.white.opacity(0.7))
                )
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }

    private func gradientColors(for id: UUID) -> [Color] {
        let seed = abs(id.hashValue)
        let palettes: [[Color]] = [
            [Theme.Colors.blue, Theme.Colors.teal],
            [Theme.Colors.danger, Theme.Colors.warning],
            [Theme.Colors.teal, Theme.Colors.blue],
            [Theme.Colors.dark, Theme.Colors.midSlate],
        ]
        return palettes[seed % palettes.count]
    }
}
