import SwiftUI

/// Named color swatches used as list color tags. Stored by `name` on `ShoppingList`.
enum AppPalette: String, CaseIterable, Identifiable {
    case green
    case blue
    case purple
    case orange
    case pink
    case teal
    case red
    case indigo

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .green: return Color(red: 0.26, green: 0.70, blue: 0.46)
        case .blue: return Color(red: 0.25, green: 0.55, blue: 0.90)
        case .purple: return Color(red: 0.55, green: 0.42, blue: 0.85)
        case .orange: return Color(red: 0.95, green: 0.58, blue: 0.25)
        case .pink: return Color(red: 0.92, green: 0.45, blue: 0.62)
        case .teal: return Color(red: 0.20, green: 0.68, blue: 0.68)
        case .red: return Color(red: 0.88, green: 0.36, blue: 0.38)
        case .indigo: return Color(red: 0.36, green: 0.40, blue: 0.78)
        }
    }

    var title: String { rawValue.capitalized }

    static func color(named name: String) -> Color {
        AppPalette(rawValue: name)?.color ?? AppPalette.green.color
    }
}
