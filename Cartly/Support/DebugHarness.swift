#if DEBUG
import SwiftUI
import SwiftData

/// DEBUG-only screen that opens straight into the first list's detail view.
/// Used for screenshot verification via the `-openFirstList` launch argument.
/// Compiled out of release builds.
struct DebugDetailHarness: View {
    @Query(sort: \ShoppingList.createdAt, order: .reverse) private var lists: [ShoppingList]

    var body: some View {
        NavigationStack {
            if let first = lists.first(where: { $0.hasPrices }) ?? lists.first {
                ListDetailView(list: first)
                    .sheet(isPresented: $showSpending) { SpendingSheet(list: first) }
                    .onAppear {
                        if ProcessInfo.processInfo.arguments.contains("-openSpending") {
                            showSpending = true
                        }
                    }
            } else {
                Text("No lists to preview")
            }
        }
    }

    @State private var showSpending = false
}
#endif
