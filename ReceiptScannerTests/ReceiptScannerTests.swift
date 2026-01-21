import XCTest
import SwiftData
@testable import ReceiptScanner

final class ReceiptScannerTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([Receipt.self, Item.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    func testReceiptCreation() throws {
        let receipt = Receipt(
            merchantName: "Costco",
            merchantType: .costco,
            total: 150.99
        )

        modelContext.insert(receipt)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<Receipt>()
        let receipts = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(receipts.count, 1)
        XCTAssertEqual(receipts.first?.merchantName, "Costco")
        XCTAssertEqual(receipts.first?.total, 150.99)
    }

    func testItemCreation() throws {
        let item = Item(
            name: "Organic Milk",
            price: 6.99,
            quantity: 2,
            taxCode: .exempt,
            category: .dairy
        )

        XCTAssertEqual(item.name, "Organic Milk")
        XCTAssertEqual(item.price, 6.99)
        XCTAssertEqual(item.quantity, 2)
        XCTAssertEqual(item.taxCode, .exempt)
        XCTAssertEqual(item.category, .dairy)
    }

    func testReceiptWithItems() throws {
        let receipt = Receipt(
            merchantName: "T&T Supermarket",
            merchantType: .tnt,
            total: 45.50
        )

        let item1 = Item(name: "白菜 Bok Choy", price: 3.99, category: .produce)
        let item2 = Item(name: "豆腐 Tofu", price: 2.49, category: .produce)

        receipt.items = [item1, item2]

        modelContext.insert(receipt)
        try modelContext.save()

        let fetchDescriptor = FetchDescriptor<Receipt>()
        let receipts = try modelContext.fetch(fetchDescriptor)

        XCTAssertEqual(receipts.first?.items.count, 2)
    }

    func testMerchantTypeDetection() {
        XCTAssertEqual(MerchantType.costco.displayName, "Costco")
        XCTAssertEqual(MerchantType.tnt.displayName, "T&T")
        XCTAssertEqual(MerchantType.walmart.displayName, "Walmart")
    }

    func testTaxCodeRates() {
        XCTAssertEqual(TaxCode.hst.rate, 0.13)
        XCTAssertEqual(TaxCode.hstWalmart.rate, 0.13)
        XCTAssertEqual(TaxCode.exempt.rate, 0)
        XCTAssertEqual(TaxCode.none.rate, 0)
    }
}
