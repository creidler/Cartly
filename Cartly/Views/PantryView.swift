import SwiftUI
import SwiftData

/// Catalog of previously bought products. Tap one to drop it into a list.
struct PantryView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: [SortDescriptor(\PantryItem.useCount, order: .reverse),
                  SortDescriptor(\PantryItem.lastUsed, order: .reverse)])
    private var pantry: [PantryItem]
    @Query private var lists: [ShoppingList]

    @State private var search = ""
    @State private var pendingItem: PantryItem?
    @State private var toast: String?

    private var filtered: [PantryItem] {
        guard !search.trimmingCharacters(in: .whitespaces).isEmpty else { return pantry }
        let q = search.lowercased()
        return pantry.filter { $0.name.lowercased().contains(q) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if pantry.isEmpty {
                    EmptyStateView(
                        symbol: "tray.full",
                        title: "Pantry is empty",
                        message: "Items you add to lists are remembered here for one-tap reordering."
                    )
                } else {
                    List {
                        Section {
                            ForEach(filtered) { item in
                                Button {
                                    handleTap(item)
                                } label: {
                                    HStack(spacing: 12) {
                                        CategoryBadge(category: item.category)
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.name)
                                                .foregroundStyle(.primary)
                                            Text(item.category.title)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        if item.useCount > 1 {
                                            Text("×\(item.useCount)")
                                                .font(.caption.weight(.medium))
                                                .foregroundStyle(.secondary)
                                        }
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(AppPalette.green.color)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        context.delete(item)
                                        try? context.save()
                                    } label: { Label("Remove", systemImage: "trash") }
                                }
                            }
                        } footer: {
                            Text("Tap an item to add it to a list.")
                        }
                    }
                }
            }
            .navigationTitle("Pantry")
            .searchable(text: $search, prompt: "Search products")
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(.subheadline.weight(.medium))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(.bottom, 12)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .confirmationDialog(
                pendingItem.map { "Add \($0.name) to…" } ?? "",
                isPresented: Binding(
                    get: { pendingItem != nil && lists.count > 1 },
                    set: { if !$0 { pendingItem = nil } }
                ),
                titleVisibility: .visible
            ) {
                ForEach(lists.sorted { $0.createdAt > $1.createdAt }) { list in
                    Button(list.name) {
                        if let item = pendingItem { add(item, to: list) }
                        pendingItem = nil
                    }
                }
                Button("Cancel", role: .cancel) { pendingItem = nil }
            }
        }
    }

    private func handleTap(_ item: PantryItem) {
        if lists.isEmpty {
            showToast("Create a list first")
            return
        }
        if lists.count == 1 {
            add(item, to: lists[0])
        } else {
            pendingItem = item
        }
    }

    private func add(_ pantryItem: PantryItem, to list: ShoppingList) {
        let nextIndex = (list.items.map(\.sortIndex).max() ?? -1) + 1
        let item = GroceryItem(
            name: pantryItem.name,
            quantity: 1,
            unit: pantryItem.unit,
            category: pantryItem.category,
            sortIndex: nextIndex
        )
        item.list = list
        context.insert(item)
        pantryItem.useCount += 1
        pantryItem.lastUsed = Date()
        try? context.save()
        showToast("Added to \(list.name)")
    }

    private func showToast(_ message: String) {
        withAnimation { toast = message }
        Task {
            try? await Task.sleep(for: .seconds(1.6))
            withAnimation { toast = nil }
        }
    }
}
