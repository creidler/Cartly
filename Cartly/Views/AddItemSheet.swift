import SwiftUI
import SwiftData

/// Add a new item to a list, or edit an existing one.
struct AddItemSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    let list: ShoppingList
    var editingItem: GroceryItem?

    @AppStorage(Money.storageKey) private var currencyCode = Money.currentCode

    @State private var name = ""
    @State private var quantity = 1.0
    @State private var unit: Unit = .pcs
    @State private var category: GroceryCategory = .other
    @State private var note = ""
    @State private var price = 0.0
    /// Becomes true once the user hand-picks a category so we stop auto-guessing.
    @State private var categoryManuallySet = false

    private var isEditing: Bool { editingItem != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Item") {
                    TextField("e.g. Bananas", text: $name)
                        .textInputAutocapitalization(.words)
                        .onChange(of: name) { _, newValue in
                            guard !categoryManuallySet else { return }
                            if let guess = Catalog.suggestedCategory(for: newValue) {
                                category = guess
                            }
                        }

                    TextField("Note (optional)", text: $note)
                        .textInputAutocapitalization(.sentences)
                }

                Section {
                    Stepper(value: $quantity, in: 1...999, step: 1) {
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text(quantityText)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Picker("Unit", selection: $unit) {
                        ForEach(Unit.allCases) { u in
                            Text(u.label).tag(u)
                        }
                    }
                    HStack {
                        Text("Price")
                        Spacer()
                        Text(Money.symbol(for: currencyCode))
                            .foregroundStyle(.secondary)
                        TextField("0", value: $price, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 90)
                    }
                } header: {
                    Text("Quantity")
                } footer: {
                    if price > 0 {
                        Text("Line total: \(Money.format(price * quantity, code: currencyCode))")
                    }
                }

                Section("Category") {
                    Picker("Category", selection: $category) {
                        ForEach(GroceryCategory.allCases) { cat in
                            Label(cat.title, systemImage: cat.symbol).tag(cat)
                        }
                    }
                    .onChange(of: category) { _, _ in categoryManuallySet = true }
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Add") { save() }
                        .disabled(trimmedName.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear(perform: loadEditing)
        }
    }

    private var quantityText: String {
        let q = quantity.rounded() == quantity ? String(Int(quantity)) : String(format: "%.1f", quantity)
        return "\(q) \(unit.label)"
    }

    private func loadEditing() {
        guard let item = editingItem else { return }
        name = item.name
        quantity = item.quantity
        unit = item.unit
        category = item.category
        note = item.note
        price = item.price
        categoryManuallySet = true
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }

        if let item = editingItem {
            item.name = trimmedName
            item.quantity = quantity
            item.unit = unit
            item.category = category
            item.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
            item.price = max(0, price)
        } else {
            let nextIndex = (list.items.map(\.sortIndex).max() ?? -1) + 1
            let item = GroceryItem(
                name: trimmedName,
                quantity: quantity,
                unit: unit,
                category: category,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                price: max(0, price),
                sortIndex: nextIndex
            )
            item.list = list
            context.insert(item)
        }

        Catalog.remember(name: trimmedName, category: category, unit: unit, in: context)
        try? context.save()
        dismiss()
    }
}
