import Foundation
import SwiftData

/// A named shopping list (e.g. "Weekly Groceries", "Party").
@Model
final class ShoppingList {
    var name: String = ""
    /// Name of an `AppPalette` swatch used as the list's color tag.
    var colorName: String = "green"
    var createdAt: Date = Date()

    /// Stable identifier used to key the list's local notification.
    var uuid: String = ""
    var reminderEnabled: Bool = false
    var reminderDate: Date = Date()
    /// Optional spend cap; 0 means "no budget".
    var budget: Double = 0

    @Relationship(deleteRule: .cascade, inverse: \GroceryItem.list)
    var items: [GroceryItem] = []

    init(name: String, colorName: String = "green", createdAt: Date = Date()) {
        self.name = name
        self.colorName = colorName
        self.createdAt = createdAt
        self.uuid = UUID().uuidString
    }

    /// Identifier for the scheduled `UNNotificationRequest`. Backfills `uuid`
    /// for rows created before the field existed.
    var notificationID: String {
        "cartly-list-\(uuid)"
    }

    /// Assigns a uuid if missing (e.g. legacy rows). Safe to call repeatedly.
    func ensureUUID() {
        if uuid.isEmpty { uuid = UUID().uuidString }
    }

    // MARK: - Derived

    var sortedItems: [GroceryItem] {
        items.sorted { $0.sortIndex < $1.sortIndex }
    }

    var activeItems: [GroceryItem] { items.filter { !$0.isChecked } }
    var checkedItems: [GroceryItem] { items.filter { $0.isChecked } }

    var totalCount: Int { items.count }
    var checkedCount: Int { checkedItems.count }

    /// 0...1 completion ratio; 0 when the list is empty.
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(checkedCount) / Double(totalCount)
    }

    var isComplete: Bool { totalCount > 0 && checkedCount == totalCount }

    // MARK: - Spending

    /// Estimated total across every item that has a price.
    var estimatedTotal: Double { items.reduce(0) { $0 + $1.lineTotal } }

    /// Total of items already checked off (what's "in the cart").
    var checkedTotal: Double { checkedItems.reduce(0) { $0 + $1.lineTotal } }

    var hasPrices: Bool { items.contains { $0.hasPrice } }
    var hasBudget: Bool { budget > 0 }

    /// 0...1 share of budget consumed by the estimated total (capped at 1 for bars).
    var budgetUsage: Double {
        guard budget > 0 else { return 0 }
        return min(estimatedTotal / budget, 1)
    }

    var isOverBudget: Bool { budget > 0 && estimatedTotal > budget }

    /// Spend per aisle, highest first — drives the breakdown chart.
    func spendingByCategory() -> [(category: GroceryCategory, amount: Double)] {
        let groups = Dictionary(grouping: items.filter { $0.hasPrice }) { $0.category }
        return groups
            .map { (category: $0.key, amount: $0.value.reduce(0) { $0 + $1.lineTotal }) }
            .filter { $0.amount > 0 }
            .sorted { $0.amount > $1.amount }
    }

    /// Items grouped by aisle and sorted for display.
    func groupedActiveItems() -> [(category: GroceryCategory, items: [GroceryItem])] {
        let groups = Dictionary(grouping: activeItems) { $0.category }
        return groups
            .map { (category: $0.key, items: $0.value.sorted { $0.sortIndex < $1.sortIndex }) }
            .sorted { $0.category.sortOrder < $1.category.sortOrder }
    }
}
