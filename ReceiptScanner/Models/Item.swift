import Foundation
import SwiftData

@Model
final class Item {
    var id: UUID
    var name: String
    var price: Decimal
    var quantity: Int
    var unitPrice: Decimal
    var taxCode: TaxCode
    var category: ItemCategory
    var itemCode: String?

    var receipt: Receipt?

    init(
        id: UUID = UUID(),
        name: String = "",
        price: Decimal = 0,
        quantity: Int = 1,
        unitPrice: Decimal = 0,
        taxCode: TaxCode = .none,
        category: ItemCategory = .uncategorized,
        itemCode: String? = nil
    ) {
        self.id = id
        self.name = name
        self.price = price
        self.quantity = quantity
        self.unitPrice = unitPrice.isZero ? price : unitPrice
        self.taxCode = taxCode
        self.category = category
        self.itemCode = itemCode
    }

    var totalPrice: Decimal {
        price * Decimal(quantity)
    }
}

enum TaxCode: String, Codable, CaseIterable {
    case hst = "H"          // HST 13% (Ontario)
    case exempt = "E"       // Tax Exempt
    case none = ""          // No Tax
    case hstWalmart = "J"   // Walmart HST
    case zeroRated = "D"    // Zero-rated (Walmart)
    case multiBuy = "M"     // Multi-buy rewards

    var description: String {
        switch self {
        case .hst, .hstWalmart:
            return "HST (13%)"
        case .exempt, .zeroRated:
            return "Tax Exempt"
        case .none:
            return "No Tax"
        case .multiBuy:
            return "Multi-buy"
        }
    }

    var rate: Decimal {
        switch self {
        case .hst, .hstWalmart:
            return 0.13
        default:
            return 0
        }
    }
}

enum ItemCategory: String, Codable, CaseIterable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat"
    case bakery = "Bakery"
    case frozen = "Frozen"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case household = "Household"
    case personal = "Personal Care"
    case uncategorized = "Uncategorized"

    var icon: String {
        switch self {
        case .produce: return "leaf"
        case .dairy: return "cup.and.saucer"
        case .meat: return "fish"
        case .bakery: return "birthday.cake"
        case .frozen: return "snowflake"
        case .beverages: return "waterbottle"
        case .snacks: return "popcorn"
        case .household: return "house"
        case .personal: return "heart"
        case .uncategorized: return "questionmark.circle"
        }
    }
}
