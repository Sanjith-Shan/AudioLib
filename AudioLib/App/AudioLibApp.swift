import SwiftUI

@main
struct AudioLibApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let persistence = PersistenceController.shared

    init() {
        AudioSessionManager.shared.activate()
        LocalNotifications.requestPermission()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
