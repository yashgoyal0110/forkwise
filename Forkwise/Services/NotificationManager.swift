import Foundation
import UserNotifications

/// Thin wrapper around `UNUserNotificationCenter` for local meal reminders.
///
/// Local notifications (no server needed) are a clean way to show you can work
/// with iOS system frameworks and permissions. We ask for permission once, then
/// schedule a daily reminder that suggests a food fitting the user's diet and
/// remaining calories.
@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    /// Requests permission to show alerts. Safe to call on every launch - iOS
    /// only prompts the user the first time.
    func requestAuthorization() async {
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification authorization failed: \(error)")
        }
    }

    /// Schedules (or replaces) a daily reminder at the given hour suggesting a dish.
    func scheduleMealReminder(hour: Int, suggestion dish: Dish?) {
        let identifier = "forkwise.daily.reminder"
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        let content = UNMutableNotificationContent()
        content.title = "Time to eat 🍽"
        if let dish {
            content.body = "\(dish.name) fits your plan today - only \(dish.calories) kcal."
        } else {
            content.body = "Log your meal in Forkwise to stay on track."
        }
        content.sound = .default

        var date = DateComponents()
        date.hour = hour
        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)

        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        center.add(request)
    }

    /// Removes the scheduled daily reminder (when the user turns it off).
    func cancelMealReminder() {
        center.removePendingNotificationRequests(withIdentifiers: ["forkwise.daily.reminder"])
    }
}
