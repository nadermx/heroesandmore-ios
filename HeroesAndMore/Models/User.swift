import Foundation

struct User: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let dateJoined: Date?

    enum CodingKeys: String, CodingKey {
        case id, username, email
        case dateJoined = "date_joined"
    }
}

struct Profile: Codable, Identifiable {
    let id: Int
    let username: String
    let email: String
    let avatar: String?
    let avatarUrl: String?
    let bio: String?
    let location: String?
    let website: String?
    let isSellerVerified: Bool
    let stripeAccountComplete: Bool
    let sellerTier: String?
    let rating: Double?
    let ratingCount: Int
    let totalSalesCount: Int
    let isPublic: Bool
    let emailNotifications: Bool
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, username, email, avatar, bio, location, website, rating, created
        case avatarUrl = "avatar_url"
        case isSellerVerified = "is_seller_verified"
        case stripeAccountComplete = "stripe_account_complete"
        case sellerTier = "seller_tier"
        case ratingCount = "rating_count"
        case totalSalesCount = "total_sales_count"
        case isPublic = "is_public"
        case emailNotifications = "email_notifications"
    }
}

struct PublicProfile: Codable {
    let username: String
    let avatarUrl: String?
    let bio: String?
    let location: String?
    let website: String?
    let rating: Double?
    let ratingCount: Int
    let isSellerVerified: Bool
    let totalSalesCount: Int
    let listingsCount: Int
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case username, bio, location, website, rating, created
        case avatarUrl = "avatar_url"
        case ratingCount = "rating_count"
        case isSellerVerified = "is_seller_verified"
        case totalSalesCount = "total_sales_count"
        case listingsCount = "listings_count"
    }
}

struct AuthTokens: Codable {
    let access: String
    let refresh: String
}

struct RegisterRequest: Codable {
    let username: String
    let email: String
    let password: String
    let passwordConfirm: String

    enum CodingKeys: String, CodingKey {
        case username, email, password
        case passwordConfirm = "password_confirm"
    }
}

struct LoginRequest: Codable {
    let username: String
    let password: String
}
