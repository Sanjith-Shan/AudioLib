import UserNotifications

class LocalNotifications {
    static func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    static func scheduleDownloadComplete(bookTitle: String) {
        let content = UNMutableNotificationContent()
        content.title = "Download Complete"
        content.body = "\"\(bookTitle)\" is ready to listen."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
}
