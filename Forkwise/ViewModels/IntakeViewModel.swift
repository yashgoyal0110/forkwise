import Foundation
import Combine
import CoreData

/// Tracks what the user has logged eating, and derives the dashboard numbers.
///
/// Reads/writes `CDIntakeEntry` rows and computes today's total plus a 7-day
/// series for the Swift Charts view.
@MainActor
final class IntakeViewModel: ObservableObject {
    @Published private(set) var todayEntries: [CDIntakeEntry] = []
    @Published private(set) var caloriesToday: Int = 0
    @Published private(set) var last7Days: [DayCalories] = []

    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
        refresh()
    }

    /// One bar in the weekly chart.
    struct DayCalories: Identifiable {
        let id = UUID()
        let date: Date
        let calories: Int
        var label: String {
            date.formatted(.dateTime.weekday(.abbreviated))
        }
    }

    /// Records that the user ate a dish from the catalog right now.
    func log(_ dish: Dish) {
        log(name: dish.name, calories: dish.calories, dishID: dish.id)
    }

    /// Logs an arbitrary meal - used by the AI "scan a meal" feature, where the
    /// food isn't one of the catalog dishes.
    func log(name: String, calories: Int, dishID: String? = nil) {
        let entry = CDIntakeEntry(context: context)
        entry.id = UUID()
        entry.dishID = dishID
        entry.name = name
        entry.calories = Int32(calories)
        entry.loggedAt = Date()
        try? context.save()
        refresh()
    }

    /// Removes a logged entry (swipe-to-delete in the UI).
    func delete(_ entry: CDIntakeEntry) {
        context.delete(entry)
        try? context.save()
        refresh()
    }

    /// Recomputes today's list, today's total, and the weekly series.
    func refresh() {
        let calendar = Calendar.current
        let start = calendar.startOfDay(for: Date())

        // Today's entries, newest first.
        let todayRequest = CDIntakeEntry.fetchRequest()
                todayRequest.predicate = NSPredicate(format: "loggedAt >= %@", start as NSDate)
                todayRequest.sortDescriptors = [NSSortDescriptor(key: "loggedAt", ascending: false)]
                todayEntries = (try? context.fetch(todayRequest)) ?? []
                caloriesToday = todayEntries.reduce(0) { $0 + Int($1.calories) }

                // Last 7 days (including today), oldest first.
                guard let weekAgo = calendar.date(byAdding: .day, value: -6, to: start) else {
                        last7Days = []
                        return
                }
                let weekRequest = CDIntakeEntry.fetchRequest()
                weekRequest.predicate = NSPredicate(format: "loggedAt >= %@", weekAgo as NSDate)
                let weekEntries = (try? context.fetch(weekRequest)) ?? []

                // Bucket calories into each of the 7 days.
                var buckets: [Date: Int] = [:]
                for entry in weekEntries {
                        guard let logged = entry.loggedAt else { continue }
                        let day = calendar.startOfDay(for: logged)
                        buckets[day, default: 0] += Int(entry.calories)
                }
                last7Days = (0..<7).compactMap { offset in
                        guard let day = calendar.date(byAdding: .day, value: offset, to: weekAgo) else { return nil }
                        return DayCalories(date: day, calories: buckets[day] ?? 0)
                }
        }
}
