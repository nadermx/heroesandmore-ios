import Foundation

struct Notification: Codable, Identifiable {
    let id: Int
    let type: String
    let title: String
    let message: String
    let isRead: Bool
    let data: NotificationData?
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, type, title, message, data, created
        case isRead = "is_read"
    }
}

struct NotificationData: Codable {
    let listingId: Int?
    let orderId: Int?
    let userId: Int?

    enum CodingKeys: String, CodingKey {
        case listingId = "listing_id"
        case orderId = "order_id"
        case userId = "user_id"
    }
}

struct Wishlist: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let isPublic: Bool
    let itemCount: Int
    let items: [WishlistItem]?
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, description, items, created
        case isPublic = "is_public"
        case itemCount = "item_count"
    }
}

struct WishlistItem: Codable, Identifiable {
    let id: Int
    let priceGuideItem: PriceGuideItemSummary?
    let customName: String?
    let maxPrice: String?
    let notes: String?
    let matchingListingsCount: Int

    enum CodingKeys: String, CodingKey {
        case id, notes
        case priceGuideItem = "price_guide_item"
        case customName = "custom_name"
        case maxPrice = "max_price"
        case matchingListingsCount = "matching_listings_count"
    }

    var displayName: String {
        customName ?? priceGuideItem?.name ?? "Unknown Item"
    }
}

struct SavedSearch: Codable, Identifiable {
    let id: Int
    let name: String
    let query: String
    let filters: SavedSearchFilters?
    let notifyEmail: Bool
    let notifyPush: Bool
    let newResultsCount: Int
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, name, query, filters, created
        case notifyEmail = "notify_email"
        case notifyPush = "notify_push"
        case newResultsCount = "new_results_count"
    }
}

struct SavedSearchFilters: Codable {
    let categoryId: Int?
    let minPrice: String?
    let maxPrice: String?
    let condition: String?
    let listingType: String?

    enum CodingKeys: String, CodingKey {
        case categoryId = "category_id"
        case minPrice = "min_price"
        case maxPrice = "max_price"
        case condition
        case listingType = "listing_type"
    }
}

struct PriceAlert: Codable, Identifiable {
    let id: Int
    let priceGuideItem: PriceGuideItemSummary
    let targetPrice: String
    let alertType: String // "below", "above"
    let isActive: Bool
    let triggered: Bool
    let triggeredAt: Date?
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, triggered, created
        case priceGuideItem = "price_guide_item"
        case targetPrice = "target_price"
        case alertType = "alert_type"
        case isActive = "is_active"
        case triggeredAt = "triggered_at"
    }
}
