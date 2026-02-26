import Foundation
import Observation
import UserNotifications

/// Manages local notification scheduling for calendar alerts.
@Observable
final class NotificationManager {
    var isAuthorized = false

    init() {
        Task { await checkAuthorization() }
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run { isAuthorized = granted }
            return granted
        } catch {
            return false
        }
    }

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            isAuthorized = settings.authorizationStatus == .authorized
        }
    }

    func scheduleNotification(
        for eventTitle: String,
        at date: Date,
        identifier: String,
        body: String? = nil
    ) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = eventTitle
        content.body = body ?? "Upcoming event"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: date
            ),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    func cancelNotification(identifier: String) {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
