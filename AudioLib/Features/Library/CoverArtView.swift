import SwiftUI

struct CoverArtView: View {
    let book: Book
    let size: CGFloat
    var cornerRadius: CGFloat = Theme.Radius.cover

    var body: some View {
        Group {
            if let artURL = book.artURL,
               FileManager.default.fileExists(atPath: artURL.path),
               let platformImage = PlatformImage(contentsOfFile: artURL.path) {
                Image(platformImage: platformImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.black.opacity(0.22), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.18), radius: size * 0.06, y: size * 0.02)
    }

    // MARK: - Typographic placeholder (warm gradient + serif title)

    private var placeholder: some View {
        let palette = self.palette
        let fg = Color(hex: palette.fg)
        return ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [Color(hex: palette.bg0), Color(hex: palette.bg1)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            // spine highlight
            LinearGradient(
                colors: [.white.opacity(0.18), .clear],
                startPoint: .leading, endPoint: .trailing
            )
            .frame(width: size * 0.05)
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 0) {
                Text(book.title)
                    .font(.custom("Georgia-Bold", size: size * 0.15))
                    .foregroundStyle(fg)
                    .lineLimit(3)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 2)
                if let author = book.author, size >= 56 {
                    Text(author)
                        .font(.custom("Georgia-Italic", size: max(7, size * 0.07)))
                        .foregroundStyle(fg.opacity(0.85))
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, size * 0.09)
            .padding(.vertical, size * 0.1)
        }
    }

    private var palette: CoverPalette {
        CoverArtView.palettes[abs(book.id.hashValue) % CoverArtView.palettes.count]
    }

    struct CoverPalette {
        let bg0: Int
        let bg1: Int
        let fg: Int
    }

    static let palettes: [CoverPalette] = [
        CoverPalette(bg0: 0x0F3D38, bg1: 0x2A8077, fg: 0xF4E4B8),
        CoverPalette(bg0: 0xD14B3A, bg1: 0xB83025, fg: 0xFFF8E7),
        CoverPalette(bg0: 0x1B4B7A, bg1: 0x0F2D4D, fg: 0xF2E9D5),
        CoverPalette(bg0: 0x2D1B5A, bg1: 0x0A0820, fg: 0xFFFFFF),
        CoverPalette(bg0: 0xC9853C, bg1: 0x8C4A1F, fg: 0x1A0F08),
        CoverPalette(bg0: 0x2A2A2A, bg1: 0x0E0E0E, fg: 0xF4E4B8),
    ]
}
