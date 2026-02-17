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
    let quantityAvailable: Int?
    let saveCount: Int?
    let recentBids: Int?

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
        case quantityAvailable = "quantity_available"
        case saveCount = "save_count"
        case recentBids = "recent_bids"
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

    var isHotLot: Bool {
        (recentBids ?? 0) >= 5 || (saveCount ?? 0) >= 10
    }
}

struct ListingSeller: Codable {
    let username: String
    let avatarUrl: String?
    let rating: Double?
    let ratingCount: Int
    let isVerified: Bool
    let isTrustedSeller: Bool

    enum CodingKeys: String, CodingKey {
        case username, rating
        case avatarUrl = "avatar_url"
        case ratingCount = "rating_count"
        case isVerified = "is_verified"
        case isTrustedSeller = "is_trusted_seller"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decode(String.self, forKey: .username)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        rating = try container.decodeIfPresent(Double.self, forKey: .rating)
        ratingCount = try container.decode(Int.self, forKey: .ratingCount)
        isVerified = try container.decode(Bool.self, forKey: .isVerified)
        isTrustedSeller = try container.decodeIfPresent(Bool.self, forKey: .isTrustedSeller) ?? false
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
    let quantity: Int?
    let quantityAvailable: Int?
    let quantitySold: Int?
    let bids: [Bid]?
    let relatedListings: [Listing]?
    let watcherCount: Int?
    let recentBidCount: Int?
    let bidWarActive: Bool?
    let compsRange: CompsRange?
    let bidHistory: [BidHistoryItem]?
    let sellerIsTrusted: Bool?

    enum CodingKeys: String, CodingKey {
        case id, title, description, price, condition, status, images, seller, category, item, created, bids, quantity
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
        case quantityAvailable = "quantity_available"
        case quantitySold = "quantity_sold"
        case relatedListings = "related_listings"
        case watcherCount = "watcher_count"
        case recentBidCount = "recent_bid_count"
        case bidWarActive = "bid_war_active"
        case compsRange = "comps_range"
        case bidHistory = "bid_history"
        case sellerIsTrusted = "seller_is_trusted"
    }
}

struct CompsRange: Codable {
    let low: String
    let high: String
}

struct BidHistoryItem: Codable, Identifiable {
    var id: String { "\(bidder)-\(amount)" }
    let bidder: String
    let amount: String
    let created: String
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
    let slug: String?
    let isPlatformEvent: Bool
    let cadence: String?
    let acceptingSubmissions: Bool
    let submissionDeadline: Date?

    enum CodingKeys: String, CodingKey {
        case id, title, description, status, slug, cadence
        case imageUrl = "image_url"
        case startDate = "start_date"
        case endDate = "end_date"
        case listingCount = "listing_count"
        case isPlatformEvent = "is_platform_event"
        case acceptingSubmissions = "accepting_submissions"
        case submissionDeadline = "submission_deadline"
    }

    init(
        id: Int,
        title: String,
        description: String? = nil,
        imageUrl: String? = nil,
        startDate: Date? = nil,
        endDate: Date? = nil,
        status: String,
        listingCount: Int = 0,
        slug: String? = nil,
        isPlatformEvent: Bool = false,
        cadence: String? = nil,
        acceptingSubmissions: Bool = false,
        submissionDeadline: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.imageUrl = imageUrl
        self.startDate = startDate
        self.endDate = endDate
        self.status = status
        self.listingCount = listingCount
        self.slug = slug
        self.isPlatformEvent = isPlatformEvent
        self.cadence = cadence
        self.acceptingSubmissions = acceptingSubmissions
        self.submissionDeadline = submissionDeadline
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        startDate = try container.decodeIfPresent(Date.self, forKey: .startDate)
        endDate = try container.decodeIfPresent(Date.self, forKey: .endDate)
        status = try container.decode(String.self, forKey: .status)
        listingCount = try container.decodeIfPresent(Int.self, forKey: .listingCount) ?? 0
        slug = try container.decodeIfPresent(String.self, forKey: .slug)
        isPlatformEvent = try container.decodeIfPresent(Bool.self, forKey: .isPlatformEvent) ?? false
        cadence = try container.decodeIfPresent(String.self, forKey: .cadence)
        acceptingSubmissions = try container.decodeIfPresent(Bool.self, forKey: .acceptingSubmissions) ?? false
        submissionDeadline = try container.decodeIfPresent(Date.self, forKey: .submissionDeadline)
    }
}

struct AuctionLotSubmission: Codable, Identifiable {
    let id: Int
    let listingId: Int
    let listingTitle: String
    let listingImage: String?
    let eventName: String
    let eventSlug: String
    let status: String
    let staffNotes: String?
    let submittedAt: Date?
    let reviewedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, status
        case listingId = "listing_id"
        case listingTitle = "listing_title"
        case listingImage = "listing_image"
        case eventName = "event_name"
        case eventSlug = "event_slug"
        case staffNotes = "staff_notes"
        case submittedAt = "submitted_at"
        case reviewedAt = "reviewed_at"
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
