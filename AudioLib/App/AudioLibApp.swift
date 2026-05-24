import SwiftUI

@main
struct AudioLibApp: App {
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    #else
    @NSApplicationDelegateAdaptor(AppDelegateMac.self) var appDelegate
    #endif

    let persistence = PersistenceController.shared
    #if os(macOS)
    @AppStorage("mac.menuBarExtra") private var menuBarExtra = true
    #endif

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

        MenuBarExtra("AudioLib", systemImage: "headphones", isInserted: $menuBarExtra) {
            MacMenuBarExtra()
        }
        .menuBarExtraStyle(.window)
        #endif
    }
}
