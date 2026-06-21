import SwiftUI
import Charts

/// Spending breakdown for a list: donut chart by aisle, totals, budget bar.
struct SpendingSheet: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Money.storageKey) private var currencyCode = Money.currentCode

    let list: ShoppingList

    private var breakdown: [(category: GroceryCategory, amount: Double)] {
        list.spendingByCategory()
    }

    var body: some View {
        NavigationStack {
            Group {
                if breakdown.isEmpty {
                    EmptyStateView(
                        symbol: "tag",
                        title: "No prices yet",
                        message: "Add a price to your items to see how your spend breaks down by aisle."
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            donut
                            if list.hasBudget { budgetCard }
                            legend
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Spending")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Donut

    private var donut: some View {
        Chart(breakdown, id: \.category) { slice in
            SectorMark(
                angle: .value("Amount", slice.amount),
                innerRadius: .ratio(0.62),
                angularInset: 1.5
            )
            .cornerRadius(4)
            .foregroundStyle(slice.category.tint)
        }
        .chartLegend(.hidden)
        .frame(height: 240)
        .overlay {
            VStack(spacing: 2) {
                Text("Estimated")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(Money.format(list.estimatedTotal, code: currencyCode))
                    .font(.title2.weight(.bold))
                    .contentTransition(.numericText())
            }
        }
    }

    // MARK: - Budget

    private var budgetCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Budget")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(Money.format(list.budget, code: currencyCode))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(list.isOverBudget ? Color.red : AppPalette.green.color)
                        .frame(width: geo.size.width * list.budgetUsage)
                }
            }
            .frame(height: 12)

            Text(budgetMessage)
                .font(.caption)
                .foregroundStyle(list.isOverBudget ? .red : .secondary)
        }
        .padding()
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var budgetMessage: String {
        let diff = abs(list.budget - list.estimatedTotal)
        if list.isOverBudget {
            return "Over budget by \(Money.format(diff, code: currencyCode))"
        }
        return "\(Money.format(diff, code: currencyCode)) left in budget"
    }

    // MARK: - Legend

    private var legend: some View {
        VStack(spacing: 0) {
            ForEach(breakdown, id: \.category) { slice in
                HStack(spacing: 12) {
                    CategoryBadge(category: slice.category, size: 30)
                    Text(slice.category.title)
                    Spacer()
                    Text(Money.format(slice.amount, code: currencyCode))
                        .foregroundStyle(.secondary)
                    Text(percent(slice.amount))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(slice.category.tint)
                        .frame(width: 44, alignment: .trailing)
                }
                .padding(.vertical, 10)
                if slice.category != breakdown.last?.category {
                    Divider()
                }
            }
        }
        .padding(.horizontal)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func percent(_ amount: Double) -> String {
        guard list.estimatedTotal > 0 else { return "0%" }
        return "\(Int((amount / list.estimatedTotal * 100).rounded()))%"
    }
}
