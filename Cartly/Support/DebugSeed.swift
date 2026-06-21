#if DEBUG
import Foundation
import SwiftData

/// Seeds sample lists + pantry when launched with `-seedPreviewData`.
/// Compiled out of release builds.
enum DebugSeed {
    static func populate(_ context: ModelContext) {
        // Don't double-seed.
        let existing = try? context.fetch(FetchDescriptor<ShoppingList>())
        guard (existing?.isEmpty ?? true) else { return }

        let weekly = ShoppingList(name: "Weekly Groceries", colorName: "green")
        weekly.budget = 60
        context.insert(weekly)
        let weeklyItems: [(String, Double, Unit, GroceryCategory, Bool, Double)] = [
            ("Bananas", 6, .pcs, .produce, false, 0.40),
            ("Spinach", 1, .pack, .produce, true, 2.20),
            ("Whole Milk", 2, .l, .dairy, false, 1.30),
            ("Greek Yogurt", 4, .pcs, .dairy, false, 1.10),
            ("Sourdough Bread", 1, .pcs, .bakery, true, 3.50),
            ("Chicken Breast", 1, .kg, .meat, false, 8.90),
            ("Olive Oil", 1, .bottle, .pantry, false, 7.40),
            ("Sparkling Water", 6, .bottle, .beverages, false, 0.80),
        ]
        for (i, row) in weeklyItems.enumerated() {
            let item = GroceryItem(name: row.0, quantity: row.1, unit: row.2, category: row.3, price: row.5, sortIndex: i)
            item.isChecked = row.4
            item.list = weekly
            context.insert(item)
        }

        let party = ShoppingList(name: "Weekend Party", colorName: "purple")
        context.insert(party)
        let partyItems: [(String, Double, Unit, GroceryCategory)] = [
            ("Tortilla Chips", 2, .pack, .snacks),
            ("Guacamole", 1, .box, .produce),
            ("Sparkling Wine", 2, .bottle, .beverages),
            ("Paper Cups", 1, .pack, .household),
        ]
        for (i, row) in partyItems.enumerated() {
            let item = GroceryItem(name: row.0, quantity: row.1, unit: row.2, category: row.3, sortIndex: i)
            item.list = party
            context.insert(item)
        }

        // Pantry catalog
        let pantry: [(String, GroceryCategory, Unit, Int)] = [
            ("Eggs", .dairy, .dozen, 9),
            ("Bananas", .produce, .pcs, 7),
            ("Whole Milk", .dairy, .l, 6),
            ("Coffee Beans", .beverages, .pack, 4),
            ("Pasta", .pantry, .pack, 4),
            ("Tomatoes", .produce, .pcs, 3),
            ("Dish Soap", .household, .bottle, 2),
        ]
        for row in pantry {
            let p = PantryItem(name: row.0, category: row.1, unit: row.2)
            p.useCount = row.3
            context.insert(p)
        }

        try? context.save()
    }
}
#endif
