import SwiftUI

/// Aisle-style categories used to group items inside a list.
/// Stored on `GroceryItem` as a raw `String` so SwiftData stays simple.
enum GroceryCategory: String, CaseIterable, Identifiable, Codable {
    case produce
    case dairy
    case bakery
    case meat
    case seafood
    case frozen
    case pantry
    case snacks
    case beverages
    case household
    case personalCare
    case other

    var id: String { rawValue }

    var title: String {
        switch self {
        case .produce: return "Produce"
        case .dairy: return "Dairy & Eggs"
        case .bakery: return "Bakery"
        case .meat: return "Meat"
        case .seafood: return "Seafood"
        case .frozen: return "Frozen"
        case .pantry: return "Pantry"
        case .snacks: return "Snacks"
        case .beverages: return "Beverages"
        case .household: return "Household"
        case .personalCare: return "Personal Care"
        case .other: return "Other"
        }
    }

    /// SF Symbols only — the simulator renders emoji as tofu glyphs.
    var symbol: String {
        switch self {
        case .produce: return "carrot.fill"
        case .dairy: return "carton.fill"
        case .bakery: return "birthday.cake.fill"
        case .meat: return "fork.knife"
        case .seafood: return "fish.fill"
        case .frozen: return "snowflake"
        case .pantry: return "shippingbox.fill"
        case .snacks: return "popcorn.fill"
        case .beverages: return "cup.and.saucer.fill"
        case .household: return "house.fill"
        case .personalCare: return "heart.fill"
        case .other: return "basket.fill"
        }
    }

    var tint: Color {
        switch self {
        case .produce: return Color(red: 0.30, green: 0.72, blue: 0.40)
        case .dairy: return Color(red: 0.95, green: 0.80, blue: 0.35)
        case .bakery: return Color(red: 0.82, green: 0.58, blue: 0.34)
        case .meat: return Color(red: 0.86, green: 0.38, blue: 0.42)
        case .seafood: return Color(red: 0.35, green: 0.62, blue: 0.80)
        case .frozen: return Color(red: 0.42, green: 0.74, blue: 0.90)
        case .pantry: return Color(red: 0.78, green: 0.62, blue: 0.45)
        case .snacks: return Color(red: 0.90, green: 0.55, blue: 0.30)
        case .beverages: return Color(red: 0.55, green: 0.45, blue: 0.82)
        case .household: return Color(red: 0.45, green: 0.65, blue: 0.70)
        case .personalCare: return Color(red: 0.88, green: 0.50, blue: 0.66)
        case .other: return Color(red: 0.55, green: 0.58, blue: 0.62)
        }
    }

    /// Stable display order used when grouping a list by aisle.
    var sortOrder: Int { Self.allCases.firstIndex(of: self) ?? 99 }
}
