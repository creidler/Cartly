import Foundation
import UserNotifications

/// Thin wrapper over `UNUserNotificationCenter` for per-list shopping reminders.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private var center: UNUserNotificationCenter { .current() }

    /// Ask once for alert/sound permission. Returns whether we're authorized.
    @discardableResult
    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// (Re)schedule or cancel the reminder for a list based on its current state.
    func sync(_ list: ShoppingList) {
        list.ensureUUID()
        cancel(id: list.notificationID)

        guard list.reminderEnabled, list.reminderDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = list.name.isEmpty ? "Shopping reminder" : list.name
        let remaining = list.activeItems.count
        content.body = remaining > 0
            ? "\(remaining) item\(remaining == 1 ? "" : "s") still to buy."
            : "Time to go shopping."
        content.sound = .default

        let comps = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: list.reminderDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: list.notificationID, content: content, trigger: trigger)
        center.add(request)
    }

    func cancel(id: String) {
        center.removePendingNotificationRequests(withIdentifiers: [id])
    }
}

/// Presents reminders as banners even while the app is foregrounded.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }
}
