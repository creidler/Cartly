import SwiftUI
import SwiftData
import UserNotifications

@main
struct CartlyApp: App {
    let container: ModelContainer
    private let notificationDelegate = NotificationDelegate()

    init() {
        UNUserNotificationCenter.current().delegate = notificationDelegate

        let schema = Schema([
            ShoppingList.self,
            GroceryItem.self,
            PantryItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }

        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-seedPreviewData") {
            DebugSeed.populate(container.mainContext)
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("-openFirstList") {
                DebugDetailHarness()
            } else {
                RootView()
            }
            #else
            RootView()
            #endif
        }
        .modelContainer(container)
    }
}
