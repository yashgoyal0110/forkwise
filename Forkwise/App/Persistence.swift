import CoreData

/// The Core Data stack. One `NSPersistentContainer` owns the SQLite store and
/// hands out the `viewContext` the UI reads from.
///
/// This is the standard "PersistenceController" pattern Apple ships in the
/// Xcode template - kept deliberately small so it's easy to explain: it loads
/// the `Forkwise` model, and offers an in-memory variant used by SwiftUI previews
/// and unit tests so they never touch the real on-disk database.
struct PersistenceController {
    static let shared = PersistenceController()

    /// An in-memory stack for previews/tests - data lives only for the session.
    static let preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        return controller
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "Forkwise")

        if inMemory {
            // Writing to /dev/null keeps everything in RAM.
            container.persistentStoreDescriptions.first?.url =
                URL(fileURLWithPath: "/dev/null")
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                // In a shipping app you'd log this and recover gracefully; for a
                // local store this only fails on genuinely unexpected conditions.
                assertionFailure("Core Data failed to load: \(error), \(error.userInfo)")
            }
        }
        // Merge background changes automatically so the UI stays fresh.
        container.viewContext.automaticallyMergesChangesFromParent = true
    }

    /// Saves the view context if there are pending changes. Safe to call freely.
    func save() {
        let context = container.viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            assertionFailure("Core Data save failed: \(error)")
        }
    }

    /// Deletes every row in every entity - backs the "reset all data" action in
    /// Settings. Uses `NSBatchDeleteRequest` so it stays fast as data grows.
    func wipeAllData() {
        let context = container.viewContext
        for entity in container.managedObjectModel.entities {
            guard let name = entity.name else { continue }
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: name)
            let delete = NSBatchDeleteRequest(fetchRequest: fetch)
            _ = try? context.execute(delete)
        }
        context.reset()
    }
}
