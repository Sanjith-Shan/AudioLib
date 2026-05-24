#if os(macOS)
import SwiftUI
import AppKit

/// Content for the menu-bar popover (NSStatusItem via MenuBarExtra .window).
struct MacMenuBarExtra: View {
    @State private var player = PlayerController.shared

    var body: some View {
        VStack(spacing: 0) {
            if let book = player.currentBook {
                HStack(spacing: 10) {
                    CoverArtView(book: book, size: 42, cornerRadius: 6)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(book.title).font(.ui(12.5, weight: .semibold)).foregroundStyle(Theme.Colors.ink).lineLimit(1)
                        Text("\(book.author ?? "") · \(DurationFormatter.format(seconds: player.currentTime)) / \(DurationFormatter.format(seconds: player.duration))")
                            .font(.ui(10.5)).foregroundStyle(Theme.Colors.inkSoft).lineLimit(1)
                    }
                    Spacer(minLength: 4)
                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 12)).foregroundStyle(Theme.Colors.paperFg)
                            .frame(width: 30, height: 30).background(Theme.Colors.ink).clipShape(Circle())
                    }.buttonStyle(.plain)
                }
                .padding(8)
                ProgressBarView(value: player.duration > 0 ? player.currentTime / player.duration : 0,
                                height: 3, color: Theme.Colors.teal)
                    .padding(.horizontal, 8).padding(.bottom, 8)
                Divider()
                menuItem("Bookmark this position", systemImage: "bookmark") { player.addBookmark() }
                menuItem("Open in AudioLib", systemImage: "chevron.up") { openMain() }
                menuItem("Quit AudioLib", systemImage: "xmark") { NSApp.terminate(nil) }
            } else {
                Text("Nothing playing").font(.ui(12.5)).foregroundStyle(Theme.Colors.inkSoft).padding(16)
                Divider()
                menuItem("Open in AudioLib", systemImage: "chevron.up") { openMain() }
                menuItem("Quit AudioLib", systemImage: "xmark") { NSApp.terminate(nil) }
            }
        }
        .frame(width: 320)
        .padding(6)
    }

    private func menuItem(_ label: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage).font(.system(size: 12)).foregroundStyle(Theme.Colors.inkSoft).frame(width: 16)
                Text(label).font(.ui(12.5, weight: .medium)).foregroundStyle(Theme.Colors.ink)
                Spacer()
            }
            .padding(.horizontal, 10).padding(.vertical, 7)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func openMain() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows where window.canBecomeMain && window.title != "" || window.isMiniaturizable {
            window.makeKeyAndOrderFront(nil)
        }
    }
}
#endif
