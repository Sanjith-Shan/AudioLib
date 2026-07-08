#if os(macOS)
import SwiftUI

/// Persistent bottom player bar (78pt, dark ink, full width). Shown whenever a
/// book is loaded. Click the cover or the expand chevron to open Now Playing.
struct MacPlayerBar: View {
    @Bindable var model: MacAppModel
    @State private var player = PlayerController.shared

    @State private var showSpeed = false
    @State private var showSleep = false
    @State private var showBookmarks = false
    @State private var showChapters = false

    private let paper = Theme.Colors.paperFg
    private var muted: Color { Theme.Colors.paperFg.opacity(0.55) }

    var body: some View {
        HStack(spacing: 16) {
            leftZone
            centerZone
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
            rightZone
        }
        .padding(.horizontal, 16)
        .frame(height: 78)
        .background(Theme.Colors.ink.opacity(0.97))
        .overlay(alignment: .top) { Rectangle().fill(.black.opacity(0.4)).frame(height: 0.5) }
        .sheet(isPresented: $showSpeed) { SpeedSheet() }
        .sheet(isPresented: $showSleep) { SleepTimerSheet() }
        .sheet(isPresented: $showBookmarks) { if let b = player.currentBook { BookmarksSheet(book: b) } }
        .sheet(isPresented: $showChapters) { if let b = player.currentBook { ChaptersSheet(book: b) } }
    }

    // MARK: - Left

    private var leftZone: some View {
        HStack(spacing: 12) {
            if let book = player.currentBook {
                CoverArtView(book: book, size: 54, cornerRadius: 6)
                VStack(alignment: .leading, spacing: 1) {
                    Text(book.title)
                        .font(.ui(13, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    if let author = book.author {
                        Text(author)
                            .font(.ui(11.5))
                            .foregroundStyle(muted)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 280, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture { model.showExpandedPlayer = true }
    }

    // MARK: - Center

    private var centerZone: some View {
        VStack(spacing: 6) {
            HStack(spacing: 18) {
                barButton("gobackward.15", size: 17) { player.skipBackward() }
                barButton("chevron.left", size: 12, color: muted) { MacPlayback.previousChapter() }
                Button { player.togglePlayPause() } label: {
                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.Colors.ink)
                        .frame(width: 32, height: 32)
                        .background(paper)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                barButton("chevron.right", size: 12, color: muted) { MacPlayback.nextChapter() }
                barButton("goforward.15", size: 17) { player.skipForward() }
            }
            scrubber
        }
    }

    private var scrubber: some View {
        HStack(spacing: 10) {
            Text(DurationFormatter.format(seconds: player.currentTime))
                .font(.mono(10.5)).foregroundStyle(muted)
                .frame(width: 54, alignment: .trailing)
            Slider(
                value: Binding(
                    get: { player.duration > 0 ? player.currentTime / player.duration : 0 },
                    set: { player.seek(to: $0 * player.duration) }
                ), in: 0...1
            )
            .controlSize(.mini)
            .tint(paper)
            Text("-\(DurationFormatter.format(seconds: max(0, player.duration - player.currentTime)))")
                .font(.mono(10.5)).foregroundStyle(muted)
                .frame(width: 54, alignment: .leading)
        }
    }

    // MARK: - Right

    private var rightZone: some View {
        HStack(spacing: 4) {
            Button { showSpeed = true } label: {
                Text(MacPlayback.rateLabel(player.playbackRate))
                    .font(.ui(11.5, weight: .bold)).monospacedDigit()
                    .foregroundStyle(paper.opacity(0.85))
                    .padding(.horizontal, 8).frame(height: 24)
            }.buttonStyle(.plain)

            Button { showSleep = true } label: {
                HStack(spacing: 4) {
                    Image(systemName: player.isSleepTimerActive ? "moon.fill" : "moon")
                        .font(.system(size: 12))
                    if player.isSleepTimerActive, let label = sleepCountdown {
                        Text(label).font(.ui(10.5, weight: .semibold)).monospacedDigit()
                    }
                }
                .foregroundStyle(player.isSleepTimerActive ? Theme.Colors.teal : muted)
                .padding(.horizontal, 6).frame(height: 24)
                .background(player.isSleepTimerActive ? Theme.Colors.teal.opacity(0.22) : .clear)
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }.buttonStyle(.plain)

            barButton("list.bullet", size: 13, color: muted) { showChapters = true }
            barButton("bookmark", size: 13, color: muted) { showBookmarks = true }

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Image(systemName: "speaker.fill").font(.system(size: 11)).foregroundStyle(muted)
                Slider(
                    value: Binding(
                        get: { Double(player.volumeBoost) },
                        set: { player.volumeBoost = Float($0) }
                    ),
                    in: 0...Double(PlayerController.maxVolumeBoost)
                )
                .controlSize(.mini)
                .tint(player.volumeBoost > 1.001 ? Theme.Colors.teal : paper.opacity(0.8))
                .frame(width: 78)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(player.volumeBoost > 1.001 ? Theme.Colors.teal : muted)
            }
            .help("Volume — above 100% boosts beyond system max")

            Button { model.showExpandedPlayer = true } label: {
                Image(systemName: "chevron.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(paper.opacity(0.85))
                    .frame(width: 26, height: 26)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Circle())
            }.buttonStyle(.plain)
            .help("Expand to Now Playing")
        }
        .frame(width: 280, alignment: .trailing)
    }

    // MARK: - Helpers

    private func barButton(_ symbol: String, size: CGFloat, color: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size, weight: .regular))
                .foregroundStyle(color ?? paper.opacity(0.85))
        }
        .buttonStyle(.plain)
    }

    private var sleepCountdown: String? {
        guard let end = player.sleepTimerEndDate else { return nil }
        let remaining = Int(max(0, end.timeIntervalSinceNow))
        return String(format: "%d:%02d", remaining / 60, remaining % 60)
    }
}
#endif
