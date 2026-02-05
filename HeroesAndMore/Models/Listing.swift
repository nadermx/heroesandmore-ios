import Foundation

struct Listing: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let price: String
    let currentBid: String?
    let buyNowPrice: String?
    let condition: String?
    let conditionDisplay: String?
    let listingType: String
    let status: String
    let image1: String?
    let image2: String?
    let image3: String?
    let image4: String?
    let seller: ListingSeller
    let category: ListingCategory?
    let item: ListingItem?
    let bidCount: Int
    let watchCount: Int
    let viewCount: Int
    let isWatched: Bool?
    let endDate: Date?
    let created: Date?
    let shippingPrice: String?
    let acceptsOffers: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, condition, status, seller, category, item, created
        case currentBid = "current_bid"
        case buyNowPrice = "buy_now_price"
        case conditionDisplay = "condition_display"
        case listingType = "listing_type"
        case image1 = "image_1"
        case image2 = "image_2"
        case image3 = "image_3"
        case image4 = "image_4"
        case bidCount = "bid_count"
        case watchCount = "watch_count"
        case viewCount = "view_count"
        case isWatched = "is_watched"
        case endDate = "end_date"
        case shippingPrice = "shipping_price"
        case acceptsOffers = "accepts_offers"
    }

    var priceDecimal: Decimal {
        Decimal(string: price) ?? 0
    }

    var primaryImageURL: URL? {
        guard let image1 = image1 else { return nil }
        return URL(string: image1)
    }

    var allImageURLs: [URL] {
        [image1, image2, image3, image4]
            .compactMap { $0 }
            .compactMap { URL(string: $0) }
    }

    var isAuction: Bool {
        listingType == "auction"
    }
}

struct ListingSeller: Codable {
    let username: String
    let avatarUrl: String?
    let rating: Double?
    let ratingCount: Int
    let isVerified: Bool

    enum CodingKeys: String, CodingKey {
        case username, rating
        case avatarUrl = "avatar_url"
        case ratingCount = "rating_count"
        case isVerified = "is_verified"
    }
}

struct ListingCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
}

struct ListingItem: Codable, Identifiable {
    let id: Int
    let name: String
    let year: Int?
}

struct ListingDetail: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let price: String
    let currentBid: String?
    let buyNowPrice: String?
    let condition: String?
    let conditionDisplay: String?
    let listingType: String
    let status: String
    let images: [ListingImage]
    let seller: ListingSeller
    let category: ListingCategory?
    let item: ListingItem?
    let bidCount: Int
    let watchCount: Int
    let viewCount: Int
    let isWatched: Bool
    let isMine: Bool
    let endDate: Date?
    let created: Date?
    let shippingPrice: String?
    let acceptsOffers: Bool
    let bids: [Bid]?
    let relatedListings: [Listing]?

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, condition, status, images, seller, category, item, created, bids
        case currentBid = "current_bid"
        case buyNowPrice = "buy_now_price"
        case conditionDisplay = "condition_display"
        case listingType = "listing_type"
        case bidCount = "bid_count"
        case watchCount = "watch_count"
        case viewCount = "view_count"
        case isWatched = "is_watched"
        case isMine = "is_mine"
        case endDate = "end_date"
        case shippingPrice = "shipping_price"
        case acceptsOffers = "accepts_offers"
        case relatedListings = "related_listings"
    }
}

struct ListingImage: Codable, Identifiable {
    let id: Int
    let url: String
    let thumbnail: String?
    let isPrimary: Bool?

    enum CodingKeys: String, CodingKey {
        case id, url, thumbnail
        case isPrimary = "is_primary"
    }
}

struct Bid: Codable, Identifiable {
    let id: Int
    let amount: String
    let bidder: String
    let created: Date?
    let isWinning: Bool

    enum CodingKeys: String, CodingKey {
        case id, amount, bidder, created
        case isWinning = "is_winning"
    }
}

struct Offer: Codable, Identifiable {
    let id: Int
    let listing: OfferListing
    let amount: String
    let message: String?
    let status: String
    let isFromBuyer: Bool
    let counterAmount: String?
    let counterMessage: String?
    let expiresAt: Date?
    let timeRemaining: String?
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, listing, amount, message, status, created
        case isFromBuyer = "is_from_buyer"
        case counterAmount = "counter_amount"
        case counterMessage = "counter_message"
        case expiresAt = "expires_at"
        case timeRemaining = "time_remaining"
    }
}

struct OfferListing: Codable, Identifiable {
    let id: Int
    let title: String
    let price: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, title, price
        case imageUrl = "image_url"
    }
}

struct PaginatedResponse<T: Codable>: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [T]
}

struct AutoBid: Codable, Identifiable {
    let id: Int
    let listing: AutoBidListing
    let maxAmount: String
    let isActive: Bool
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, listing, created
        case maxAmount = "max_amount"
        case isActive = "is_active"
    }
}

struct AutoBidListing: Codable, Identifiable {
    let id: Int
    let title: String
    let currentBid: String?
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, title
        case currentBid = "current_bid"
        case imageUrl = "image_url"
    }
}

struct AuctionEvent: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let imageUrl: String?
    let startDate: Date?
    let endDate: Date?
    let status: String
    let listingCount: Int

    enum CodingKeys: String, CodingKey {
        case id, title, description, status
        case imageUrl = "image_url"
        case startDate = "start_date"
        case endDate = "end_date"
        case listingCount = "listing_count"
    }
}

struct CheckoutResponse: Codable {
    let orderId: Int
    let total: String
    let subtotal: String
    let shipping: String
    let fee: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case total, subtotal, shipping, fee, status
        case orderId = "order_id"
    }
}

struct PaymentIntentResponse: Codable {
    let clientSecret: String
    let paymentIntentId: String
    let amount: Int
    let currency: String

    enum CodingKeys: String, CodingKey {
        case amount, currency
        case clientSecret = "client_secret"
        case paymentIntentId = "payment_intent_id"
    }
}

struct PaymentConfirmResponse: Codable {
    let success: Bool
    let orderId: Int?
    let status: String
    let message: String?

    enum CodingKeys: String, CodingKey {
        case success, status, message
        case orderId = "order_id"
    }
}
