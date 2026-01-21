import Foundation
import SwiftData

@Model
final class Receipt {
    var id: UUID
    var merchantName: String
    var merchantType: MerchantType
    var date: Date
    var subtotal: Decimal
    var taxAmount: Decimal
    var total: Decimal
    var rawText: String
    var imageData: Data?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Item.receipt)
    var items: [Item]

    init(
        id: UUID = UUID(),
        merchantName: String = "",
        merchantType: MerchantType = .unknown,
        date: Date = Date(),
        subtotal: Decimal = 0,
        taxAmount: Decimal = 0,
        total: Decimal = 0,
        rawText: String = "",
        imageData: Data? = nil,
        items: [Item] = []
    ) {
        self.id = id
        self.merchantName = merchantName
        self.merchantType = merchantType
        self.date = date
        self.subtotal = subtotal
        self.taxAmount = taxAmount
        self.total = total
        self.rawText = rawText
        self.imageData = imageData
        self.createdAt = Date()
        self.updatedAt = Date()
        self.items = items
    }
}

enum MerchantType: String, Codable, CaseIterable {
    case costco = "Costco"
    case tnt = "T&T"
    case walmart = "Walmart"
    case noFrills = "No Frills"
    case foodBasics = "Food Basics"
    case unknown = "Unknown"

    var displayName: String {
        rawValue
    }
}
