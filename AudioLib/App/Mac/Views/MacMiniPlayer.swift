#if os(macOS)
import SwiftUI
import AppKit

/// Floating mini-player window content (360×100, always-on-top, draggable).
struct MacMiniPlayer: View {
    @State private var player = PlayerController.shared

    var body: some View {
        ZStack {
            Color(hex: 0x141210).opacity(0.96).ignoresSafeArea()
            if let book = player.currentBook {
                HStack(spacing: 12) {
                    CoverArtView(book: book, size: 60, cornerRadius: 7)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(book.title).font(.ui(13, weight: .semibold)).foregroundStyle(.white).lineLimit(1)
                        Text(book.author ?? "").font(.ui(11)).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
                        HStack(spacing: 8) {
                            ProgressBarView(value: player.duration > 0 ? player.currentTime / player.duration : 0,
                                            height: 2.5, color: Theme.Colors.paperFg, track: .white.opacity(0.12))
                            Text("-\(DurationFormatter.format(seconds: max(0, player.duration - player.currentTime)))")
                                .font(.mono(10)).foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.top, 2)
                    }
                    HStack(spacing: 4) {
                        miniButton("gobackward.15", size: 15) { player.skipBackward() }
                        Button { player.togglePlayPause() } label: {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 13, weight: .semibold)).foregroundStyle(Theme.Colors.ink)
                                .frame(width: 36, height: 36).background(Theme.Colors.paperFg).clipShape(Circle())
                        }.buttonStyle(.plain)
                        miniButton("goforward.15", size: 15) { player.skipForward() }
                    }
                }
                .padding(.horizontal, 14)
            } else {
                Text("Nothing playing").font(.ui(12)).foregroundStyle(.white.opacity(0.6))
            }
        }
        .frame(width: 360, height: 100)
        .background(FloatingWindowConfigurator())
        .preferredColorScheme(.dark)
    }

    private func miniButton(_ symbol: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol).font(.system(size: size)).foregroundStyle(.white.opacity(0.8))
                .frame(width: 28, height: 28)
        }.buttonStyle(.plain)
    }
}

/// Promotes its host window to a floating, background-draggable panel.
private struct FloatingWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            guard let w = v.window else { return }
            w.level = .floating
            w.isMovableByWindowBackground = true
            w.standardWindowButton(.zoomButton)?.isEnabled = false
            w.standardWindowButton(.miniaturizeButton)?.isHidden = true
        }
        return v
    }
    func updateNSView(_ nsView: NSView, context: Context) {}
}
#endif
