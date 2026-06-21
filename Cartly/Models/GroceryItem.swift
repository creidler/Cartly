import Foundation
import SwiftData

/// A single line item inside a `ShoppingList`.
@Model
final class GroceryItem {
    var name: String = ""
    var quantity: Double = 1
    /// Raw value of `Unit`; kept as a string for SwiftData simplicity.
    var unitRaw: String = Unit.pcs.rawValue
    /// Raw value of `GroceryCategory`.
    var categoryRaw: String = GroceryCategory.other.rawValue
    var note: String = ""
    /// Unit price; 0 means "no price set".
    var price: Double = 0
    var isChecked: Bool = false
    var sortIndex: Int = 0
    var createdAt: Date = Date()

    var list: ShoppingList?

    init(
        name: String,
        quantity: Double = 1,
        unit: Unit = .pcs,
        category: GroceryCategory = .other,
        note: String = "",
        price: Double = 0,
        sortIndex: Int = 0,
        createdAt: Date = Date()
    ) {
        self.name = name
        self.quantity = quantity
        self.unitRaw = unit.rawValue
        self.categoryRaw = category.rawValue
        self.note = note
        self.price = price
        self.sortIndex = sortIndex
        self.createdAt = createdAt
    }

    /// price × quantity.
    var lineTotal: Double { price * quantity }
    var hasPrice: Bool { price > 0 }

    // MARK: - Typed accessors

    var unit: Unit {
        get { Unit(rawValue: unitRaw) ?? .pcs }
        set { unitRaw = newValue.rawValue }
    }

    var category: GroceryCategory {
        get { GroceryCategory(rawValue: categoryRaw) ?? .other }
        set { categoryRaw = newValue.rawValue }
    }

    /// "2 kg" / "3 pcs" — omits a redundant "1 pcs".
    var quantityLabel: String {
        let qty = quantity.rounded() == quantity
            ? String(Int(quantity))
            : String(format: "%.2f", quantity)
        if unit == .pcs && quantity == 1 { return "" }
        return "\(qty) \(unit.label)"
    }
}
