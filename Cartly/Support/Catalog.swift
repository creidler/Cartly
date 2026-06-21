import Foundation
import SwiftData

/// Helpers for keeping the reusable `PantryItem` catalog in sync and for
/// suggesting common starter products.
enum Catalog {

    /// Record that a product was used: bump its count or insert a new entry.
    static func remember(name: String, category: GroceryCategory, unit: Unit, in context: ModelContext) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let key = PantryItem.normalizedKey(trimmed)

        let descriptor = FetchDescriptor<PantryItem>(predicate: #Predicate { $0.key == key })
        if let existing = try? context.fetch(descriptor).first {
            existing.useCount += 1
            existing.lastUsed = Date()
            existing.categoryRaw = category.rawValue
            existing.unitRaw = unit.rawValue
        } else {
            let item = PantryItem(name: trimmed, category: category, unit: unit)
            context.insert(item)
        }
    }

    /// A small built-in dictionary so brand-new users still get smart category
    /// suggestions before they've built any history.
    static func suggestedCategory(for name: String) -> GroceryCategory? {
        let lower = name.lowercased()
        for (keywords, category) in keywordMap {
            if keywords.contains(where: { lower.contains($0) }) {
                return category
            }
        }
        return nil
    }

    private static let keywordMap: [([String], GroceryCategory)] = [
        (["apple", "banana", "tomato", "lettuce", "carrot", "onion", "potato", "pepper", "spinach", "cucumber", "lemon", "lime", "avocado", "berr", "grape", "salad", "fruit", "veg"], .produce),
        (["milk", "cheese", "yogurt", "butter", "egg", "cream", "kefir"], .dairy),
        (["bread", "bun", "bagel", "croissant", "tortilla", "baguette", "roll"], .bakery),
        (["chicken", "beef", "pork", "steak", "bacon", "sausage", "turkey", "ham", "mince"], .meat),
        (["salmon", "tuna", "shrimp", "fish", "cod", "crab"], .seafood),
        (["frozen", "ice cream", "pizza"], .frozen),
        (["rice", "pasta", "flour", "sugar", "oil", "salt", "cereal", "bean", "sauce", "spice", "honey", "oat", "noodle", "can "], .pantry),
        (["chip", "cookie", "chocolate", "candy", "snack", "cracker", "nuts", "popcorn"], .snacks),
        (["water", "juice", "soda", "coffee", "tea", "beer", "wine", "cola", "drink"], .beverages),
        (["soap", "detergent", "paper", "towel", "trash", "bag", "cleaner", "sponge", "foil", "battery"], .household),
        (["shampoo", "toothpaste", "toothbrush", "deodorant", "razor", "lotion", "tissue"], .personalCare),
    ]
}
