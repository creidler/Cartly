import SwiftUI

/// Small rounded icon chip for a grocery category.
struct CategoryBadge: View {
    var category: GroceryCategory
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(category.tint)
            .frame(width: size, height: size)
            .background(category.tint.opacity(0.16), in: RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
    }
}
