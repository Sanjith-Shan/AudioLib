#if os(macOS)
import SwiftUI

// Phase 4 replaces this stub with the full split layout (cover + tabbed
// chapters/bookmarks/notes + transport).
struct MacNowPlayingExpanded: View {
    @Bindable var model: MacAppModel
    @State private var player = PlayerController.shared

    var body: some View {
        ZStack(alignment: .top) {
            RadialGradient(
                colors: [Color(hex: 0x2A4D6F), Color(hex: 0x0E1E33), Color(hex: 0x0A0A12)],
                center: UnitPoint(x: 0.3, y: 0.2), startRadius: 40, endRadius: 900
            )
            .ignoresSafeArea()

            HStack {
                Spacer()
                Text("NOW PLAYING")
                    .font(.ui(11, weight: .semibold)).tracking(1)
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
            }
            .overlay(alignment: .trailing) {
                Button { model.showExpandedPlayer = false } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 7))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
            .frame(height: 48)

            if let book = player.currentBook {
                VStack(spacing: 24) {
                    Spacer()
                    CoverArtView(book: book, size: 360, cornerRadius: 16)
                    Text(book.title).font(.serif(30, weight: .bold)).foregroundStyle(.white)
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}
#endif
