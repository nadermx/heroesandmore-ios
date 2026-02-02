import Foundation

struct Collection: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let isPublic: Bool
    let coverImage: String?
    let itemCount: Int
    let totalValue: String?
    let created: Date?
    let updated: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, created, updated
        case isPublic = "is_public"
        case coverImage = "cover_image"
        case itemCount = "item_count"
        case totalValue = "total_value"
    }
}

struct CollectionDetail: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let isPublic: Bool
    let coverImage: String?
    let owner: CollectionOwner
    let itemCount: Int
    let totalValue: String?
    let items: [CollectionItem]
    let valueHistory: [ValueSnapshot]?
    let created: Date?
    let updated: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, owner, items, created, updated
        case isPublic = "is_public"
        case coverImage = "cover_image"
        case itemCount = "item_count"
        case totalValue = "total_value"
        case valueHistory = "value_history"
    }
}

struct CollectionOwner: Codable {
    let username: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case username
        case avatarUrl = "avatar_url"
    }
}

struct CollectionItem: Codable, Identifiable {
    let id: Int
    let priceGuideItem: PriceGuideItemSummary?
    let customName: String?
    let grade: String?
    let gradeCompany: String?
    let certNumber: String?
    let purchasePrice: String?
    let purchaseDate: Date?
    let currentValue: String?
    let notes: String?
    let image: String?
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, grade, notes, image, created
        case priceGuideItem = "price_guide_item"
        case customName = "custom_name"
        case gradeCompany = "grade_company"
        case certNumber = "cert_number"
        case purchasePrice = "purchase_price"
        case purchaseDate = "purchase_date"
        case currentValue = "current_value"
    }

    var displayName: String {
        customName ?? priceGuideItem?.name ?? "Unknown Item"
    }
}

struct PriceGuideItemSummary: Codable, Identifiable {
    let id: Int
    let name: String
    let year: Int?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, name, year
        case imageUrl = "image_url"
    }
}

struct ValueSnapshot: Codable, Identifiable {
    var id: String { date }
    let date: String
    let value: String
}

struct ValueSummary: Codable {
    let totalValue: String
    let totalCost: String
    let totalGainLoss: String
    let gainLossPercent: String
    let itemCount: Int
    let lastUpdated: Date?

    enum CodingKeys: String, CodingKey {
        case totalValue = "total_value"
        case totalCost = "total_cost"
        case totalGainLoss = "total_gain_loss"
        case gainLossPercent = "gain_loss_percent"
        case itemCount = "item_count"
        case lastUpdated = "last_updated"
    }
}

struct ImportResult: Codable {
    let collectionId: Int
    let collectionName: String
    let itemsImported: Int
    let itemsTotal: Int

    enum CodingKeys: String, CodingKey {
        case collectionId = "collection_id"
        case collectionName = "collection_name"
        case itemsImported = "items_imported"
        case itemsTotal = "items_total"
    }
}
