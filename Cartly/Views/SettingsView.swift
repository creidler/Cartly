import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Query private var lists: [ShoppingList]
    @Query private var pantry: [PantryItem]

    @AppStorage(Money.storageKey) private var currencyCode = Money.currentCode

    @State private var showingClearPantry = false
    @State private var showingDeleteAll = false

    private var totalItems: Int { lists.reduce(0) { $0 + $1.totalCount } }

    var body: some View {
        NavigationStack {
            List {
                Section("Overview") {
                    statRow(symbol: "cart.fill", title: "Lists", value: "\(lists.count)", tint: AppPalette.green.color)
                    statRow(symbol: "checklist", title: "Items", value: "\(totalItems)", tint: AppPalette.blue.color)
                    statRow(symbol: "tray.full.fill", title: "Pantry products", value: "\(pantry.count)", tint: AppPalette.purple.color)
                }

                Section("Preferences") {
                    Picker(selection: $currencyCode) {
                        ForEach(Money.supported, id: \.self) { code in
                            Text("\(code) (\(Money.symbol(for: code)))").tag(code)
                        }
                    } label: {
                        Label("Currency", systemImage: "coloncurrencysign.circle")
                    }
                }

                Section("Data") {
                    Button(role: .destructive) {
                        showingClearPantry = true
                    } label: {
                        Label("Clear Pantry", systemImage: "tray")
                    }
                    .disabled(pantry.isEmpty)

                    Button(role: .destructive) {
                        showingDeleteAll = true
                    } label: {
                        Label("Delete All Lists", systemImage: "trash")
                    }
                    .disabled(lists.isEmpty)
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                } header: {
                    Text("About")
                } footer: {
                    Text("Cartly keeps everything on your device. No account, no tracking.")
                }
            }
            .navigationTitle("Settings")
            .confirmationDialog("Clear all remembered pantry products?",
                                isPresented: $showingClearPantry, titleVisibility: .visible) {
                Button("Clear Pantry", role: .destructive) { clearPantry() }
                Button("Cancel", role: .cancel) {}
            }
            .confirmationDialog("Delete every list and its items? This cannot be undone.",
                                isPresented: $showingDeleteAll, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) { deleteAllLists() }
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private func statRow(symbol: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .foregroundStyle(tint)
                .frame(width: 28)
            Text(title)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }

    private func clearPantry() {
        for item in pantry { context.delete(item) }
        try? context.save()
    }

    private func deleteAllLists() {
        for list in lists {
            NotificationManager.shared.cancel(id: list.notificationID)
            context.delete(list)
        }
        try? context.save()
    }
}
