import SwiftUI
import SwiftData

/// Home tab: all shopping lists as cards with progress.
struct ListsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \ShoppingList.createdAt, order: .reverse) private var lists: [ShoppingList]

    @State private var editingList: ShoppingList?
    @State private var showingNewList = false

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    EmptyStateView(
                        symbol: "cart.badge.plus",
                        title: "No lists yet",
                        message: "Create your first shopping list to start adding items.",
                        actionTitle: "New List",
                        action: { showingNewList = true }
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(lists) { list in
                                NavigationLink {
                                    ListDetailView(list: list)
                                } label: {
                                    ListCard(list: list)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button {
                                        editingList = list
                                    } label: { Label("Edit", systemImage: "pencil") }
                                    Button(role: .destructive) {
                                        delete(list)
                                    } label: { Label("Delete", systemImage: "trash") }
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("Cartly")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingNewList = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.body.weight(.semibold))
                    }
                }
            }
            .sheet(isPresented: $showingNewList) {
                ListEditorSheet()
            }
            .sheet(item: $editingList) { list in
                ListEditorSheet(list: list)
            }
        }
    }

    private func delete(_ list: ShoppingList) {
        NotificationManager.shared.cancel(id: list.notificationID)
        context.delete(list)
        try? context.save()
    }
}

/// Card summarizing one list.
private struct ListCard: View {
    let list: ShoppingList

    private var color: Color { AppPalette.color(named: list.colorName) }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.opacity(0.18))
                .frame(width: 52, height: 52)
                .overlay {
                    Image(systemName: "cart.fill")
                        .font(.title3)
                        .foregroundStyle(color)
                }

            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    if list.reminderEnabled && list.reminderDate > Date() {
                        Image(systemName: "bell.fill")
                            .font(.caption2)
                            .foregroundStyle(color)
                    }
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            ProgressRing(progress: list.progress, tint: color, size: 42)
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
    }

    private var subtitle: String {
        if list.totalCount == 0 { return "Empty list" }
        if list.isComplete { return "All done · \(list.totalCount) items" }
        return "\(list.checkedCount) of \(list.totalCount) done"
    }
}

#Preview {
    ListsView()
        .modelContainer(for: [ShoppingList.self, GroceryItem.self, PantryItem.self], inMemory: true)
}
