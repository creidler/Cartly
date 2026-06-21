import SwiftUI
import SwiftData

/// Create a new list or edit an existing one's name + color.
struct ListEditorSheet: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    /// When non-nil we're editing; otherwise creating.
    var list: ShoppingList?

    @AppStorage(Money.storageKey) private var currencyCode = Money.currentCode

    @State private var name: String = ""
    @State private var colorName: String = AppPalette.green.rawValue
    @State private var reminderEnabled = false
    @State private var reminderDate = ListEditorSheet.defaultReminderDate()
    @State private var permissionDenied = false
    @State private var budget = 0.0

    private var isEditing: Bool { list != nil }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 14), count: 4)

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("e.g. Weekly Groceries", text: $name)
                        .textInputAutocapitalization(.words)
                }

                Section("Color") {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(AppPalette.allCases) { swatch in
                            Circle()
                                .fill(swatch.color)
                                .frame(height: 38)
                                .overlay {
                                    if swatch.rawValue == colorName {
                                        Image(systemName: "checkmark")
                                            .font(.subheadline.weight(.bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                                .overlay(
                                    Circle().stroke(.primary.opacity(0.08), lineWidth: 1)
                                )
                                .onTapGesture { colorName = swatch.rawValue }
                                .accessibilityLabel(swatch.title)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    HStack {
                        Text("Budget")
                        Spacer()
                        Text(Money.symbol(for: currencyCode))
                            .foregroundStyle(.secondary)
                        TextField("None", value: $budget, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 110)
                    }
                } header: {
                    Text("Budget")
                } footer: {
                    Text("Set a spend cap to track your estimated total against it.")
                }

                Section {
                    Toggle("Reminder", isOn: $reminderEnabled.animation())
                        .onChange(of: reminderEnabled) { _, isOn in
                            if isOn { requestPermission() }
                        }
                    if reminderEnabled {
                        DatePicker(
                            "When",
                            selection: $reminderDate,
                            in: Date()...,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    if permissionDenied {
                        Text("Notifications are turned off for Cartly. Enable them in Settings to get reminders.")
                            .foregroundStyle(.orange)
                    } else if reminderEnabled {
                        Text("You'll get a one-time notification at the chosen time.")
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit List" : "New List")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(trimmedName.isEmpty)
                        .fontWeight(.semibold)
                }
            }
            .onAppear {
                if let list {
                    name = list.name
                    colorName = list.colorName
                    budget = list.budget
                    reminderEnabled = list.reminderEnabled
                    if list.reminderEnabled { reminderDate = list.reminderDate }
                }
            }
        }
    }

    private func save() {
        guard !trimmedName.isEmpty else { return }
        let target: ShoppingList
        if let list {
            list.name = trimmedName
            list.colorName = colorName
            target = list
        } else {
            let new = ShoppingList(name: trimmedName, colorName: colorName)
            context.insert(new)
            target = new
        }
        target.budget = max(0, budget)
        target.reminderEnabled = reminderEnabled
        target.reminderDate = reminderDate
        try? context.save()
        NotificationManager.shared.sync(target)
        dismiss()
    }

    private func requestPermission() {
        Task {
            let granted = await NotificationManager.shared.requestAuthorization()
            await MainActor.run { permissionDenied = !granted }
        }
    }

    /// Tomorrow at 18:00 by default.
    static func defaultReminderDate() -> Date {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return cal.date(bySettingHour: 18, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }
}
