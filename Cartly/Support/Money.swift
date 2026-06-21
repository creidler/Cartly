import Foundation

/// Currency formatting shared across the app. The active currency code is
/// stored in UserDefaults under `currencyCode` and edited from Settings.
enum Money {
    static let storageKey = "currencyCode"

    /// A small curated list of common currencies for the picker.
    static let supported: [String] = ["USD", "EUR", "GBP", "UAH", "PLN", "CAD", "AUD", "JPY"]

    static var currentCode: String {
        UserDefaults.standard.string(forKey: storageKey)
            ?? Locale.current.currency?.identifier
            ?? "USD"
    }

    static func format(_ amount: Double, code: String = currentCode) -> String {
        amount.formatted(.currency(code: code).precision(.fractionLength(0...2)))
    }

    /// Symbol only, e.g. "$" / "€" — used as a text-field prefix.
    static func symbol(for code: String) -> String {
        symbols[code] ?? code
    }

    private static let symbols: [String: String] = [
        "USD": "$", "EUR": "€", "GBP": "£", "UAH": "₴",
        "PLN": "zł", "CAD": "C$", "AUD": "A$", "JPY": "¥",
    ]
}
