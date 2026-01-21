import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.date, order: .reverse) private var receipts: [Receipt]

    var body: some View {
        NavigationStack {
            List {
                if receipts.isEmpty {
                    ContentUnavailableView(
                        "No Receipts",
                        systemImage: "doc.text.magnifyingglass",
                        description: Text("Scan your first receipt to get started")
                    )
                } else {
                    ForEach(receipts) { receipt in
                        ReceiptRowView(receipt: receipt)
                    }
                    .onDelete(perform: deleteReceipts)
                }
            }
            .navigationTitle("Receipts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func deleteReceipts(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(receipts[index])
            }
        }
    }
}

struct ReceiptRowView: View {
    let receipt: Receipt

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(receipt.merchantName)
                .font(.headline)
            HStack {
                Text(receipt.date, style: .date)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(receipt.total, format: .currency(code: "CAD"))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
