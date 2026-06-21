#if DEBUG
import Foundation
import SwiftData

/// DEBUG-only helper that configures a real reminder on a list and schedules it,
/// triggered by the `-demoReminder` launch argument. Lets the reminder feature
/// be exercised end-to-end without driving the UI by hand.
enum DemoReminder {
    @MainActor
    static func setupIfRequested(_ context: ModelContext) async {
        guard ProcessInfo.processInfo.arguments.contains("-demoReminder") else { return }

        // Pick the most recently created list, or make one if the store is empty.
        let descriptor = FetchDescriptor<ShoppingList>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let list: ShoppingList
        if let first = try? context.fetch(descriptor).first {
            list = first
        } else {
            list = ShoppingList(name: "Weekly Groceries", colorName: "green")
            context.insert(list)
        }

        list.ensureUUID()
        list.reminderEnabled = true
        list.reminderDate = Date().addingTimeInterval(120) // ~2 minutes out
        try? context.save()

        // Ask for permission (system dialog appears) then schedule.
        await NotificationManager.shared.requestAuthorization()
        NotificationManager.shared.sync(list)
    }
}
#endif
