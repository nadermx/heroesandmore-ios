import Foundation

actor MarketplaceService {
    static let shared = MarketplaceService()

    private init() {}

    // MARK: - Listings

    func getListings(
        page: Int = 1,
        category: Int? = nil,
        search: String? = nil,
        listingType: String? = nil,
        condition: String? = nil,
        minPrice: String? = nil,
        maxPrice: String? = nil,
        sort: String? = nil
    ) async throws -> PaginatedResponse<Listing> {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]

        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: String(category)))
        }
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let listingType = listingType {
            queryItems.append(URLQueryItem(name: "listing_type", value: listingType))
        }
        if let condition = condition {
            queryItems.append(URLQueryItem(name: "condition", value: condition))
        }
        if let minPrice = minPrice {
            queryItems.append(URLQueryItem(name: "min_price", value: minPrice))
        }
        if let maxPrice = maxPrice {
            queryItems.append(URLQueryItem(name: "max_price", value: maxPrice))
        }
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "ordering", value: sort))
        }

        return try await APIClient.shared.request(
            path: "/marketplace/listings/",
            queryItems: queryItems
        )
    }

    func getListing(id: Int) async throws -> ListingDetail {
        return try await APIClient.shared.request(path: "/marketplace/listings/\(id)/")
    }

    func getSavedListings(page: Int = 1) async throws -> PaginatedResponse<Listing> {
        return try await APIClient.shared.request(
            path: "/marketplace/saved/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func saveListing(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/marketplace/listings/\(id)/save/",
            method: .post
        )
    }

    func unsaveListing(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/marketplace/listings/\(id)/save/",
            method: .delete
        )
    }

    // MARK: - Bidding

    func placeBid(listingId: Int, amount: String) async throws -> Bid {
        struct BidRequest: Codable {
            let amount: String
        }

        return try await APIClient.shared.request(
            path: "/marketplace/listings/\(listingId)/bid/",
            method: .post,
            body: BidRequest(amount: amount)
        )
    }

    // MARK: - Offers

    func makeOffer(listingId: Int, amount: String, message: String?) async throws -> Offer {
        struct OfferRequest: Codable {
            let amount: String
            let message: String?
        }

        return try await APIClient.shared.request(
            path: "/marketplace/listings/\(listingId)/offer/",
            method: .post,
            body: OfferRequest(amount: amount, message: message)
        )
    }

    func getOffers(page: Int = 1) async throws -> PaginatedResponse<Offer> {
        return try await APIClient.shared.request(
            path: "/marketplace/offers/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func acceptOffer(offerId: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/marketplace/offers/\(offerId)/accept/",
            method: .post
        )
    }

    func declineOffer(offerId: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/marketplace/offers/\(offerId)/decline/",
            method: .post
        )
    }

    func counterOffer(offerId: Int, amount: String, message: String?) async throws -> Offer {
        struct CounterRequest: Codable {
            let amount: String
            let message: String?
        }

        return try await APIClient.shared.request(
            path: "/marketplace/offers/\(offerId)/counter/",
            method: .post,
            body: CounterRequest(amount: amount, message: message)
        )
    }

    // MARK: - Orders

    func getOrders(page: Int = 1, type: String = "bought") async throws -> PaginatedResponse<Order> {
        return try await APIClient.shared.request(
            path: "/marketplace/orders/",
            queryItems: [
                URLQueryItem(name: "page", value: String(page)),
                URLQueryItem(name: "type", value: type)
            ]
        )
    }

    func getOrder(id: Int) async throws -> Order {
        return try await APIClient.shared.request(path: "/marketplace/orders/\(id)/")
    }

    func markOrderShipped(orderId: Int, trackingNumber: String?, carrier: String?) async throws -> Order {
        struct ShipRequest: Codable {
            let trackingNumber: String?
            let trackingCarrier: String?

            enum CodingKeys: String, CodingKey {
                case trackingNumber = "tracking_number"
                case trackingCarrier = "tracking_carrier"
            }
        }

        return try await APIClient.shared.request(
            path: "/marketplace/orders/\(orderId)/ship/",
            method: .post,
            body: ShipRequest(trackingNumber: trackingNumber, trackingCarrier: carrier)
        )
    }

    func markOrderReceived(orderId: Int) async throws -> Order {
        return try await APIClient.shared.request(
            path: "/marketplace/orders/\(orderId)/received/",
            method: .post
        )
    }

    func leaveReview(orderId: Int, rating: Int, comment: String?) async throws -> Review {
        struct ReviewRequest: Codable {
            let rating: Int
            let comment: String?
        }

        return try await APIClient.shared.request(
            path: "/marketplace/orders/\(orderId)/review/",
            method: .post,
            body: ReviewRequest(rating: rating, comment: comment)
        )
    }

    // MARK: - Auctions

    func getAuctions(page: Int = 1) async throws -> PaginatedResponse<Listing> {
        return try await APIClient.shared.request(
            path: "/marketplace/auctions/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }
}
