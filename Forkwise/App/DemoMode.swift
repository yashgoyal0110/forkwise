import Foundation
import CoreData

/// Sets up a clean, good-looking state for automated UI-test recordings.
///
/// Activated only when the app is launched with the `-uitestDemo` argument (the
/// CI UI test passes it), so it never touches a real user's data. It skips
/// onboarding, disables the notification prompt (which would interrupt a
/// recording), and seeds a profile + a few days of meals so the safety badges
/// and the dashboard chart look alive on camera.
enum DemoMode {
    static var isActive: Bool {
        ProcessInfo.processInfo.arguments.contains("-uitestDemo")
    }

    static func applyIfNeeded(context: NSManagedObjectContext) {
        guard isActive else { return }

        let defaults = UserDefaults.standard
        // Start at onboarding (so the recording shows that flow too), but with a
        // little meal history pre-seeded so the dashboard looks alive afterwards.
        defaults.set(false, forKey: "hasOnboarded")
        defaults.set(false, forKey: "reminderEnabled") // no permission dialog during recording

        wipe(context)
        seedIntake(context)
        try? context.save()
    }

    private static func wipe(_ context: NSManagedObjectContext) {
        for name in ["CDIntakeEntry", "CDFavorite", "CDProfile"] {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            _ = try? context.execute(NSBatchDeleteRequest(fetchRequest: request))
        }
        context.reset()
    }

    private static func seedIntake(_ context: NSManagedObjectContext) {
        // A little history so the 7-day chart and today's ring aren't empty.
        let calendar = Calendar.current
        let samples: [(daysAgo: Int, name: String, calories: Int)] = [
            (5, "Rajma Chawal Bowl", 540),
            (4, "Chilli Garlic Edamame", 220),
            (3, "Falafel Hummus Wrap", 480),
            (2, "Cold Brew Coffee", 15),
            (1, "Rajma Chawal Bowl", 540),
            (0, "Falafel Hummus Wrap", 480),
        ]
        for s in samples {
            let entry = CDIntakeEntry(context: context)
            entry.id = UUID()
            entry.name = s.name
            entry.calories = Int32(s.calories)
            let day = calendar.date(byAdding: .day, value: -s.daysAgo, to: Date()) ?? Date()
            entry.loggedAt = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
        }
    }
}
