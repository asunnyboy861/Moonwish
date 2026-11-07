import Foundation
import UserNotifications

enum NotificationService {
    static func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    static func authorizationStatus() async -> UNAuthorizationStatus {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
    }

    static func scheduleEveningReminder(hour: Int = 21, minute: Int = 30) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["moonwish.evening"])
        let content = UNMutableNotificationContent()
        content.title = "The Moon is rising"
        content.body = "One breath, one wish, then sleep. Your moon is waiting."
        content.sound = .default
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: "moonwish.evening", content: content, trigger: trigger)
        center.add(request)
    }

    static func scheduleTrialReminder(daysFromNow: Int = 2) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["moonwish.trial"])
        let content = UNMutableNotificationContent()
        content.title = "Your Plus trial ends soon"
        content.body = "Your 7-day trial ends in 2 days. You can cancel anytime in Settings."
        content.sound = .default
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(max(1, daysFromNow) * 86400), repeats: false)
        let request = UNNotificationRequest(identifier: "moonwish.trial", content: content, trigger: trigger)
        center.add(request)
    }

    static func scheduleTimeCapsule(wishID: UUID, wishText: String, date: Date) {
        let center = UNUserNotificationCenter.current()
        let identifier = "moonwish.capsule.\(wishID.uuidString)"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        guard date > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "Did it happen?"
        content.body = "Your wish from \(dateFormatted(date)) was: \(wishText). Tap to mark it fulfilled."
        content.sound = .default
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    static func cancelTimeCapsule(wishID: UUID) {
        let identifier = "moonwish.capsule.\(wishID.uuidString)"
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func dateFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
