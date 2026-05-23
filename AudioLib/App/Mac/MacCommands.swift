#if os(macOS)
import SwiftUI

/// Adds a "Playback" menu with standard desktop keyboard shortcuts.
/// Actions read PlayerController.shared at invocation time so they always
/// act on whatever is currently loaded.
struct PlaybackCommands: Commands {
    private static let rates: [Float] = [0.75, 1.0, 1.25, 1.5, 1.75, 2.0, 2.5, 3.0]

    var body: some Commands {
        CommandMenu("Playback") {
            Button("Play / Pause") { PlayerController.shared.togglePlayPause() }
                .keyboardShortcut("p", modifiers: .command)

            Divider()

            Button("Skip Forward") { PlayerController.shared.skipForward() }
                .keyboardShortcut(.rightArrow, modifiers: .command)

            Button("Skip Backward") { PlayerController.shared.skipBackward() }
                .keyboardShortcut(.leftArrow, modifiers: .command)

            Divider()

            Button("Increase Speed") { adjustRate(faster: true) }
                .keyboardShortcut("]", modifiers: .command)

            Button("Decrease Speed") { adjustRate(faster: false) }
                .keyboardShortcut("[", modifiers: .command)
        }
    }

    private func adjustRate(faster: Bool) {
        let player = PlayerController.shared
        let current = player.playbackRate
        // nearest index, then step
        let idx = Self.rates.enumerated().min { abs($0.1 - current) < abs($1.1 - current) }?.0 ?? 1
        let next = faster ? min(idx + 1, Self.rates.count - 1) : max(idx - 1, 0)
        player.setRate(Self.rates[next])
    }
}
#endif
