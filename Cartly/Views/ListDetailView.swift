import SwiftUI
import SwiftData

/// Items of one list, grouped by aisle, with progress header and add flow.
struct ListDetailView: View {
    @Environment(\.modelContext) private var context
    @Bindable var list: ShoppingList

    @AppStorage(Money.storageKey) private var currencyCode = Money.currentCode

    @State private var showingAddItem = false
    @State private var editingItem: GroceryItem?
    @State private var showingSpending = false
    @State private var quickText = ""
    @FocusState private var quickFocused: Bool

    private var color: Color { AppPalette.color(named: list.colorName) }

    var body: some View {
        content
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) { quickAddBar }
        .toolbar {
            if list.hasPrices {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSpending = true
                    } label: {
                        Image(systemName: "chart.pie.fill")
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showingAddItem = true
                    } label: { Label("Add Item", systemImage: "plus") }

                    if !list.checkedItems.isEmpty {
                        Button(role: .destructive) {
                            clearChecked()
                        } label: { Label("Clear Checked", systemImage: "trash") }
                    }
                    if !list.items.isEmpty {
                        Button {
                            uncheckAll()
                        } label: { Label("Uncheck All", systemImage: "arrow.counterclockwise") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingAddItem) {
            AddItemSheet(list: list)
        }
        .sheet(item: $editingItem) { item in
            AddItemSheet(list: list, editingItem: item)
        }
        .sheet(isPresented: $showingSpending) {
            SpendingSheet(list: list)
        }
    }

    @ViewBuilder
    private var content: some View {
        if list.items.isEmpty {
            EmptyStateView(
                symbol: "basket",
                title: "Empty list",
                message: "Add items and they'll be sorted into aisles automatically.",
                actionTitle: "Add Item",
                action: { showingAddItem = true }
            )
        } else {
            List {
                progressHeader
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)

                ForEach(list.groupedActiveItems(), id: \.category) { group in
                    Section {
                        ForEach(group.items) { item in
                            ItemRow(item: item, tint: color) { toggle(item) }
                                .contentShape(Rectangle())
                                .onTapGesture { editingItem = item }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(item)
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                    } header: {
                        Label(group.category.title, systemImage: group.category.symbol)
                            .foregroundStyle(group.category.tint)
                            .font(.subheadline.weight(.semibold))
                    }
                }

                if !list.checkedItems.isEmpty {
                    Section {
                        ForEach(list.checkedItems.sorted { $0.sortIndex < $1.sortIndex }) { item in
                            ItemRow(item: item, tint: color) { toggle(item) }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        delete(item)
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                        }
                    } header: {
                        Text("Done · \(list.checkedItems.count)")
                            .font(.subheadline.weight(.semibold))
                    }
                }

            }
            .listStyle(.insetGrouped)
        }
    }

    private var progressHeader: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                ProgressRing(progress: list.progress, tint: color, size: 54)
                VStack(alignment: .leading, spacing: 3) {
                    Text(list.isComplete ? "All done!" : "\(list.activeItems.count) left to buy")
                        .font(.headline)
                    Text("\(list.checkedCount) of \(list.totalCount) items checked")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if list.hasPrices {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(Money.format(list.estimatedTotal, code: currencyCode))
                            .font(.headline)
                            .foregroundStyle(list.isOverBudget ? .red : .primary)
                        Text("estimated")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if list.hasBudget && list.hasPrices {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.18))
                            Capsule()
                                .fill(list.isOverBudget ? Color.red : color)
                                .frame(width: geo.size.width * list.budgetUsage)
                        }
                    }
                    .frame(height: 8)
                    HStack {
                        Text(list.isOverBudget ? "Over budget" : "Budget")
                            .foregroundStyle(list.isOverBudget ? .red : .secondary)
                        Spacer()
                        Text(Money.format(list.budget, code: currencyCode))
                            .foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
            }
        }
        .padding(14)
        .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    /// Pinned bar for rapid one-field entry with automatic aisle detection.
    private var quickAddBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .foregroundStyle(color)

            TextField("Add item…", text: $quickText)
                .focused($quickFocused)
                .submitLabel(.done)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
                .onSubmit(addQuick)

            if !quickText.trimmingCharacters(in: .whitespaces).isEmpty {
                Button("Add", action: addQuick)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(color)
                    .transition(.opacity)
            }

            Button {
                showingAddItem = true
            } label: {
                Image(systemName: "slider.horizontal.3")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .accessibilityLabel("Add with details")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }

    private func addQuick() {
        let trimmed = quickText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let category = Catalog.suggestedCategory(for: trimmed) ?? .other
        let nextIndex = (list.items.map(\.sortIndex).max() ?? -1) + 1
        let item = GroceryItem(name: trimmed, category: category, sortIndex: nextIndex)
        item.list = list
        context.insert(item)
        Catalog.remember(name: trimmed, category: category, unit: .pcs, in: context)
        try? context.save()
        withAnimation(.snappy) { quickText = "" }
        quickFocused = true
    }

    // MARK: - Mutations

    private func toggle(_ item: GroceryItem) {
        withAnimation(.snappy) {
            item.isChecked.toggle()
        }
        try? context.save()
    }

    private func delete(_ item: GroceryItem) {
        context.delete(item)
        try? context.save()
    }

    private func clearChecked() {
        withAnimation {
            for item in list.checkedItems { context.delete(item) }
        }
        try? context.save()
    }

    private func uncheckAll() {
        withAnimation {
            for item in list.items { item.isChecked = false }
        }
        try? context.save()
    }
}

/// One item row with a check toggle, quantity and note.
struct ItemRow: View {
    @AppStorage(Money.storageKey) private var currencyCode = Money.currentCode
    @Bindable var item: GroceryItem
    var tint: Color
    var onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? tint : Color.secondary.opacity(0.5))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isChecked, color: .secondary)
                    .foregroundStyle(item.isChecked ? .secondary : .primary)
                if !item.note.isEmpty {
                    Text(item.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                if item.hasPrice {
                    Text(Money.format(item.lineTotal, code: currencyCode))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(item.isChecked ? .secondary : .primary)
                }
                if !item.quantityLabel.isEmpty {
                    Text(item.quantityLabel)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.secondary.opacity(0.12), in: Capsule())
                }
            }
        }
        .padding(.vertical, 2)
    }
}
