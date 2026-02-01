import Foundation

struct Order: Codable, Identifiable {
    let id: Int
    let orderNumber: String
    let listing: OrderListing
    let buyer: OrderUser
    let seller: OrderUser
    let total: String
    let status: String
    let statusDisplay: String
    let shippingAddress: ShippingAddress?
    let trackingNumber: String?
    let trackingCarrier: String?
    let created: Date?
    let paidAt: Date?
    let shippedAt: Date?
    let deliveredAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, listing, buyer, seller, total, status, created
        case orderNumber = "order_number"
        case statusDisplay = "status_display"
        case shippingAddress = "shipping_address"
        case trackingNumber = "tracking_number"
        case trackingCarrier = "tracking_carrier"
        case paidAt = "paid_at"
        case shippedAt = "shipped_at"
        case deliveredAt = "delivered_at"
    }
}

struct OrderListing: Codable, Identifiable {
    let id: Int
    let title: String
    let price: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case id, title, price
        case imageUrl = "image_url"
    }
}

struct OrderUser: Codable {
    let username: String
    let avatarUrl: String?

    enum CodingKeys: String, CodingKey {
        case username
        case avatarUrl = "avatar_url"
    }
}

struct ShippingAddress: Codable {
    let name: String
    let street1: String
    let street2: String?
    let city: String
    let state: String
    let zip: String
    let country: String
}

struct Review: Codable, Identifiable {
    let id: Int
    let rating: Int
    let comment: String?
    let reviewer: String
    let created: Date?
}
