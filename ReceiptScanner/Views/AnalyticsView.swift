import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Query private var receipts: [Receipt]

    var body: some View {
        NavigationStack {
            List {
                if receipts.isEmpty {
                    ContentUnavailableView(
                        "No Data",
                        systemImage: "chart.bar.xaxis",
                        description: Text("Scan some receipts to see analytics")
                    )
                } else {
                    Section("Summary") {
                        LabeledContent("Total Receipts", value: "\(receipts.count)")
                        LabeledContent("Total Spent", value: totalSpent, format: .currency(code: "CAD"))
                        LabeledContent("Average Receipt", value: averageReceipt, format: .currency(code: "CAD"))
                    }

                    Section("By Merchant") {
                        ForEach(merchantBreakdown, id: \.merchant) { item in
                            HStack {
                                Text(item.merchant)
                                Spacer()
                                Text(item.total, format: .currency(code: "CAD"))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Analytics")
        }
    }

    private var totalSpent: Decimal {
        receipts.reduce(0) { $0 + $1.total }
    }

    private var averageReceipt: Decimal {
        guard !receipts.isEmpty else { return 0 }
        return totalSpent / Decimal(receipts.count)
    }

    private var merchantBreakdown: [(merchant: String, total: Decimal)] {
        Dictionary(grouping: receipts, by: \.merchantName)
            .map { (merchant: $0.key, total: $0.value.reduce(0) { $0 + $1.total }) }
            .sorted { $0.total > $1.total }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: Receipt.self, inMemory: true)
}
