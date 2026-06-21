import Foundation

/// Optional measurement unit for an item's quantity.
enum Unit: String, CaseIterable, Identifiable, Codable {
    case pcs
    case kg
    case g
    case l
    case ml
    case pack
    case bottle
    case can
    case box
    case dozen

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pcs: return "pcs"
        case .kg: return "kg"
        case .g: return "g"
        case .l: return "L"
        case .ml: return "ml"
        case .pack: return "pack"
        case .bottle: return "bottle"
        case .can: return "can"
        case .box: return "box"
        case .dozen: return "dozen"
        }
    }
}
