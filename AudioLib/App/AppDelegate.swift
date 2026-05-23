#if os(iOS)
import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        Theme.configureAppearance()
        return true
    }

    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        if identifier == BackgroundDownloadSession.sessionID {
            BackgroundDownloadSession.shared.handleEventsForBackgroundURLSession(completionHandler)
        } else {
            completionHandler()
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        Task { await SyncService.shared.pullAndMerge() }
    }
}
#endif
