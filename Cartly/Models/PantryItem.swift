import Foundation
import SwiftData

/// A remembered product in the user's personal catalog ("pantry").
/// Every item added to a list is upserted here so frequent buys are one tap away.
@Model
final class PantryItem {
    @Attribute(.unique) var key: String = ""
    var name: String = ""
    var categoryRaw: String = GroceryCategory.other.rawValue
    var unitRaw: String = Unit.pcs.rawValue
    var useCount: Int = 0
    var lastUsed: Date = Date()

    init(name: String, category: GroceryCategory = .other, unit: Unit = .pcs) {
        self.name = name
        self.key = Self.normalizedKey(name)
        self.categoryRaw = category.rawValue
        self.unitRaw = unit.rawValue
        self.useCount = 1
        self.lastUsed = Date()
    }

    var category: GroceryCategory {
        get { GroceryCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    var unit: Unit {
        get { Unit(rawValue: unitRaw) ?? .pcs }
        set { unitRaw = newValue.rawValue }
    }

    /// Case/whitespace-insensitive identity so "Milk" and "milk " dedupe.
    static func normalizedKey(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
