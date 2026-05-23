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
            CloudSyncObserver.shared.start()
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
        Settings {
            SettingsView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
        #endif
    }
}
