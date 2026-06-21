import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            ListsView()
                .tabItem { Label("Lists", systemImage: "cart.fill") }

            PantryView()
                .tabItem { Label("Pantry", systemImage: "tray.full.fill") }

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(AppPalette.green.color)
        #if DEBUG
        .task { await DemoReminder.setupIfRequested(modelContext) }
        #endif
    }

    #if DEBUG
    @Environment(\.modelContext) private var modelContext
    #endif
}

#Preview {
    RootView()
        .modelContainer(for: [ShoppingList.self, GroceryItem.self, PantryItem.self], inMemory: true)
}
