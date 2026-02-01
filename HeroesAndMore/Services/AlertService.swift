import Foundation

actor AlertService {
    static let shared = AlertService()

    private init() {}

    // MARK: - Notifications

    func getNotifications(page: Int = 1, unreadOnly: Bool = false) async throws -> PaginatedResponse<Notification> {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]
        if unreadOnly {
            queryItems.append(URLQueryItem(name: "unread", value: "true"))
        }

        return try await APIClient.shared.request(
            path: "/alerts/notifications/",
            queryItems: queryItems
        )
    }

    func markNotificationRead(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/alerts/notifications/\(id)/read/",
            method: .post
        )
    }

    func markAllNotificationsRead() async throws {
        try await APIClient.shared.requestVoid(
            path: "/alerts/notifications/read-all/",
            method: .post
        )
    }

    // MARK: - Wishlists

    func getWishlists(page: Int = 1) async throws -> PaginatedResponse<Wishlist> {
        return try await APIClient.shared.request(
            path: "/alerts/wishlists/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func getWishlist(id: Int) async throws -> Wishlist {
        return try await APIClient.shared.request(path: "/alerts/wishlists/\(id)/")
    }

    func createWishlist(name: String, description: String?, isPublic: Bool) async throws -> Wishlist {
        struct CreateRequest: Codable {
            let name: String
            let description: String?
            let isPublic: Bool

            enum CodingKeys: String, CodingKey {
                case name, description
                case isPublic = "is_public"
            }
        }

        return try await APIClient.shared.request(
            path: "/alerts/wishlists/",
            method: .post,
            body: CreateRequest(name: name, description: description, isPublic: isPublic)
        )
    }

    func addToWishlist(
        wishlistId: Int,
        priceGuideItemId: Int?,
        customName: String?,
        maxPrice: String?,
        notes: String?
    ) async throws -> WishlistItem {
        struct AddRequest: Codable {
            let priceGuideItemId: Int?
            let customName: String?
            let maxPrice: String?
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case notes
                case priceGuideItemId = "price_guide_item_id"
                case customName = "custom_name"
                case maxPrice = "max_price"
            }
        }

        return try await APIClient.shared.request(
            path: "/alerts/wishlists/\(wishlistId)/items/",
            method: .post,
            body: AddRequest(
                priceGuideItemId: priceGuideItemId,
                customName: customName,
                maxPrice: maxPrice,
                notes: notes
            )
        )
    }

    func removeFromWishlist(wishlistId: Int, itemId: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/alerts/wishlists/\(wishlistId)/items/\(itemId)/",
            method: .delete
        )
    }

    // MARK: - Saved Searches

    func getSavedSearches(page: Int = 1) async throws -> PaginatedResponse<SavedSearch> {
        return try await APIClient.shared.request(
            path: "/alerts/saved-searches/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func createSavedSearch(
        name: String,
        query: String,
        categoryId: Int?,
        minPrice: String?,
        maxPrice: String?,
        notifyEmail: Bool,
        notifyPush: Bool
    ) async throws -> SavedSearch {
        struct CreateRequest: Codable {
            let name: String
            let query: String
            let categoryId: Int?
            let minPrice: String?
            let maxPrice: String?
            let notifyEmail: Bool
            let notifyPush: Bool

            enum CodingKeys: String, CodingKey {
                case name, query
                case categoryId = "category_id"
                case minPrice = "min_price"
                case maxPrice = "max_price"
                case notifyEmail = "notify_email"
                case notifyPush = "notify_push"
            }
        }

        return try await APIClient.shared.request(
            path: "/alerts/saved-searches/",
            method: .post,
            body: CreateRequest(
                name: name,
                query: query,
                categoryId: categoryId,
                minPrice: minPrice,
                maxPrice: maxPrice,
                notifyEmail: notifyEmail,
                notifyPush: notifyPush
            )
        )
    }

    func deleteSavedSearch(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/alerts/saved-searches/\(id)/",
            method: .delete
        )
    }

    // MARK: - Price Alerts

    func getPriceAlerts(page: Int = 1) async throws -> PaginatedResponse<PriceAlert> {
        return try await APIClient.shared.request(
            path: "/alerts/price-alerts/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func createPriceAlert(
        priceGuideItemId: Int,
        targetPrice: String,
        alertType: String
    ) async throws -> PriceAlert {
        struct CreateRequest: Codable {
            let priceGuideItemId: Int
            let targetPrice: String
            let alertType: String

            enum CodingKeys: String, CodingKey {
                case priceGuideItemId = "price_guide_item_id"
                case targetPrice = "target_price"
                case alertType = "alert_type"
            }
        }

        return try await APIClient.shared.request(
            path: "/alerts/price-alerts/",
            method: .post,
            body: CreateRequest(
                priceGuideItemId: priceGuideItemId,
                targetPrice: targetPrice,
                alertType: alertType
            )
        )
    }

    func deletePriceAlert(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/alerts/price-alerts/\(id)/",
            method: .delete
        )
    }
}
