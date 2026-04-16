import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        handleEventsForBackgroundURLSession identifier: String,
        completionHandler: @escaping () -> Void
    ) {
        if identifier == "com.sanjith.audiolib.bg" {
            DownloadManager.shared.handleBackgroundCompletion(completionHandler)
        } else {
            completionHandler()
        }
    }
}
