import SwiftUI

@main
struct AudioLibApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
    @NSApplicationDelegateAdaptor(AppDelegateMac.self) var appDelegate
    #endif

    let persistence = PersistenceController.shared

    init() {
        Task { @MainActor in
            DownloadManager.shared.reconnectOnLaunch()
        }
    }

    var body: some Scene {
        WindowGroup {
            #if os(iOS)
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
            #else
            MacRootView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
            #endif
        }
        #if os(macOS)
        .windowStyle(.hiddenTitleBar)
        .commands {
            PlaybackCommands()
        }
        #endif
        #if os(macOS)
        Settings {
            MacPreferences()
                .environment(AppRouter.shared)
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }

        Window("Mini Player", id: "mini") {
            MacMiniPlayer()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultPosition(.bottomTrailing)
        // NOTE: A MenuBarExtra is intentionally omitted. On macOS 26.1 an
        // inserted MenuBarExtra drives the main window's Buttons into an
        // infinite scroll-edge-effect update loop (100% CPU / beachball),
        // regardless of style or content. Revisit if Apple fixes it.
        #endif
    }
}
