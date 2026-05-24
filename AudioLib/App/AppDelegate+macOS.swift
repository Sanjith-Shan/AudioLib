#if os(macOS)
import AppKit

class AppDelegateMac: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        DownloadManager.shared.reconnectOnLaunch()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        Task { await SyncService.shared.pullAndMerge() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
#endif
