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

    // Buyer accepts counter-offer from seller
    func acceptCounterOffer(offerId: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/marketplace/offers/\(offerId)/accept-counter/",
            method: .post
        )
    }

    // Buyer declines counter-offer from seller
    func declineCounterOffer(offerId: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/marketplace/offers/\(offerId)/decline-counter/",
            method: .post
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

    func getAuctionEvents(page: Int = 1) async throws -> PaginatedResponse<AuctionEvent> {
        return try await APIClient.shared.request(
            path: "/marketplace/auctions/events/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func getEndingSoon(page: Int = 1) async throws -> PaginatedResponse<Listing> {
        return try await APIClient.shared.request(
            path: "/marketplace/auctions/ending-soon/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    // MARK: - Auto-Bid (Proxy Bidding)

    func setAutoBid(listingId: Int, maxAmount: String) async throws -> AutoBid {
        struct AutoBidRequest: Codable {
            let maxAmount: String

            enum CodingKeys: String, CodingKey {
                case maxAmount = "max_amount"
            }
        }

        return try await APIClient.shared.request(
            path: "/marketplace/listings/\(listingId)/autobid/",
            method: .post,
            body: AutoBidRequest(maxAmount: maxAmount)
        )
    }

    func getAutoBids(page: Int = 1) async throws -> PaginatedResponse<AutoBid> {
        return try await APIClient.shared.request(
            path: "/marketplace/auctions/autobid/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func cancelAutoBid(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/marketplace/auctions/autobid/\(id)/",
            method: .delete
        )
    }

    // MARK: - Listing Images

    func uploadListingImage(listingId: Int, imageData: Data, isPrimary: Bool = false) async throws -> ListingImage {
        var queryItems: [URLQueryItem] = []
        if isPrimary {
            queryItems.append(URLQueryItem(name: "is_primary", value: "true"))
        }

        return try await APIClient.shared.upload(
            path: "/marketplace/listings/\(listingId)/images/",
            imageData: imageData,
            filename: "listing_image.jpg",
            queryItems: queryItems
        )
    }

    func deleteListingImage(listingId: Int, imageId: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/marketplace/listings/\(listingId)/images/\(imageId)/",
            method: .delete
        )
    }

    // MARK: - Checkout & Payment

    func checkout(listingId: Int, shippingAddressId: Int? = nil) async throws -> CheckoutResponse {
        struct CheckoutRequest: Codable {
            let shippingAddressId: Int?

            enum CodingKeys: String, CodingKey {
                case shippingAddressId = "shipping_address_id"
            }
        }

        return try await APIClient.shared.request(
            path: "/marketplace/checkout/\(listingId)/",
            method: .post,
            body: CheckoutRequest(shippingAddressId: shippingAddressId)
        )
    }

    func createPaymentIntent(orderId: Int, paymentMethodId: String? = nil) async throws -> PaymentIntentResponse {
        struct PaymentIntentRequest: Codable {
            let orderId: Int
            let paymentMethodId: String?

            enum CodingKeys: String, CodingKey {
                case orderId = "order_id"
                case paymentMethodId = "payment_method_id"
            }
        }

        return try await APIClient.shared.request(
            path: "/marketplace/payment/intent/",
            method: .post,
            body: PaymentIntentRequest(orderId: orderId, paymentMethodId: paymentMethodId)
        )
    }

    func confirmPayment(paymentIntentId: String) async throws -> PaymentConfirmResponse {
        struct ConfirmRequest: Codable {
            let paymentIntentId: String

            enum CodingKeys: String, CodingKey {
                case paymentIntentId = "payment_intent_id"
            }
        }

        return try await APIClient.shared.request(
            path: "/marketplace/payment/confirm/",
            method: .post,
            body: ConfirmRequest(paymentIntentId: paymentIntentId)
        )
    }

    // MARK: - Create Listing

    func createListing(
        title: String,
        description: String,
        price: String,
        categoryId: Int,
        listingType: String = "fixed",
        condition: String? = nil,
        gradingCompany: String? = nil,
        grade: String? = nil,
        certNumber: String? = nil,
        startingBid: String? = nil,
        reservePrice: String? = nil,
        endDate: String? = nil
    ) async throws -> Listing {
        struct CreateListingRequest: Codable {
            let title: String
            let description: String
            let price: String
            let categoryId: Int
            let listingType: String
            let condition: String?
            let gradingCompany: String?
            let grade: String?
            let certNumber: String?
            let startingBid: String?
            let reservePrice: String?
            let endDate: String?

            enum CodingKeys: String, CodingKey {
                case title, description, price, condition, grade
                case categoryId = "category_id"
                case listingType = "listing_type"
                case gradingCompany = "grading_company"
                case certNumber = "cert_number"
                case startingBid = "starting_bid"
                case reservePrice = "reserve_price"
                case endDate = "end_date"
            }
        }

        return try await APIClient.shared.request(
            path: "/marketplace/listings/",
            method: .post,
            body: CreateListingRequest(
                title: title,
                description: description,
                price: price,
                categoryId: categoryId,
                listingType: listingType,
                condition: condition,
                gradingCompany: gradingCompany,
                grade: grade,
                certNumber: certNumber,
                startingBid: startingBid,
                reservePrice: reservePrice,
                endDate: endDate
            )
        )
    }

    func updateListing(id: Int, title: String?, description: String?, price: String?) async throws -> Listing {
        struct UpdateListingRequest: Codable {
            let title: String?
            let description: String?
            let price: String?
        }

        return try await APIClient.shared.request(
            path: "/marketplace/listings/\(id)/",
            method: .patch,
            body: UpdateListingRequest(title: title, description: description, price: price)
        )
    }

    func deleteListing(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/marketplace/listings/\(id)/",
            method: .delete
        )
    }

    func publishListing(id: Int) async throws -> Listing {
        return try await APIClient.shared.request(
            path: "/marketplace/listings/\(id)/publish/",
            method: .post
        )
    }
}
