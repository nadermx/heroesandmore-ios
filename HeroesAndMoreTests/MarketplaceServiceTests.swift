import XCTest
@testable import HeroesAndMore

final class MarketplaceServiceTests: XCTestCase {

    // MARK: - Model Tests

    func testListingDecoding() throws {
        let json = """
        {
            "id": 1,
            "title": "Test Card",
            "description": "A test listing",
            "price": "99.99",
            "current_bid": null,
            "buy_now_price": null,
            "condition": "mint",
            "condition_display": "Mint",
            "listing_type": "fixed",
            "status": "active",
            "image_1": "https://example.com/image.jpg",
            "image_2": null,
            "image_3": null,
            "image_4": null,
            "seller": {
                "username": "seller1",
                "avatar_url": null,
                "rating": 4.5,
                "rating_count": 10,
                "is_verified": true
            },
            "category": {
                "id": 1,
                "name": "Sports Cards",
                "slug": "sports-cards"
            },
            "item": null,
            "bid_count": 0,
            "watch_count": 5,
            "view_count": 100,
            "is_watched": false,
            "end_date": null,
            "created": "2026-01-15T10:30:00Z",
            "shipping_price": "5.00",
            "accepts_offers": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let listing = try decoder.decode(Listing.self, from: json)

        XCTAssertEqual(listing.id, 1)
        XCTAssertEqual(listing.title, "Test Card")
        XCTAssertEqual(listing.price, "99.99")
        XCTAssertEqual(listing.priceDecimal, Decimal(string: "99.99"))
        XCTAssertEqual(listing.seller.username, "seller1")
        XCTAssertEqual(listing.listingType, "fixed")
        XCTAssertFalse(listing.isAuction)
        XCTAssertNotNil(listing.primaryImageURL)
    }

    func testBidDecoding() throws {
        let json = """
        {
            "id": 1,
            "amount": "150.00",
            "bidder": "buyer1",
            "created": "2026-01-15T12:00:00Z",
            "is_winning": true
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let bid = try decoder.decode(Bid.self, from: json)

        XCTAssertEqual(bid.id, 1)
        XCTAssertEqual(bid.amount, "150.00")
        XCTAssertEqual(bid.bidder, "buyer1")
        XCTAssertTrue(bid.isWinning)
    }

    func testOfferDecoding() throws {
        let json = """
        {
            "id": 1,
            "listing": {
                "id": 5,
                "title": "Rare Card",
                "price": "200.00",
                "image_url": "https://example.com/card.jpg"
            },
            "amount": "175.00",
            "message": "Would you accept $175?",
            "status": "pending",
            "is_from_buyer": true,
            "created": "2026-01-15T14:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let offer = try decoder.decode(Offer.self, from: json)

        XCTAssertEqual(offer.id, 1)
        XCTAssertEqual(offer.amount, "175.00")
        XCTAssertEqual(offer.status, "pending")
        XCTAssertTrue(offer.isFromBuyer)
        XCTAssertEqual(offer.listing.title, "Rare Card")
    }

    func testAutoBidDecoding() throws {
        let json = """
        {
            "id": 1,
            "listing": {
                "id": 10,
                "title": "Auction Item",
                "current_bid": "50.00",
                "image_url": null
            },
            "max_amount": "100.00",
            "is_active": true,
            "created": "2026-01-15T09:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let autoBid = try decoder.decode(AutoBid.self, from: json)

        XCTAssertEqual(autoBid.id, 1)
        XCTAssertEqual(autoBid.maxAmount, "100.00")
        XCTAssertTrue(autoBid.isActive)
        XCTAssertEqual(autoBid.listing.title, "Auction Item")
    }

    func testCheckoutResponseDecoding() throws {
        let json = """
        {
            "order_id": 123,
            "total": "104.99",
            "subtotal": "99.99",
            "shipping": "5.00",
            "fee": "0.00",
            "status": "pending"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(CheckoutResponse.self, from: json)

        XCTAssertEqual(response.orderId, 123)
        XCTAssertEqual(response.total, "104.99")
        XCTAssertEqual(response.subtotal, "99.99")
        XCTAssertEqual(response.status, "pending")
    }

    func testPaymentIntentResponseDecoding() throws {
        let json = """
        {
            "client_secret": "pi_secret_123",
            "payment_intent_id": "pi_123",
            "amount": 10499,
            "currency": "usd"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(PaymentIntentResponse.self, from: json)

        XCTAssertEqual(response.clientSecret, "pi_secret_123")
        XCTAssertEqual(response.paymentIntentId, "pi_123")
        XCTAssertEqual(response.amount, 10499)
        XCTAssertEqual(response.currency, "usd")
    }

    func testAuctionEventDecoding() throws {
        let json = """
        {
            "id": 1,
            "title": "Weekly Auction",
            "description": "Our weekly sports card auction",
            "image_url": "https://example.com/auction.jpg",
            "start_date": "2026-01-20T18:00:00Z",
            "end_date": "2026-01-21T21:00:00Z",
            "status": "upcoming",
            "listing_count": 50
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let event = try decoder.decode(AuctionEvent.self, from: json)

        XCTAssertEqual(event.id, 1)
        XCTAssertEqual(event.title, "Weekly Auction")
        XCTAssertEqual(event.status, "upcoming")
        XCTAssertEqual(event.listingCount, 50)
    }

    // MARK: - Pagination Tests

    func testPaginatedResponseDecoding() throws {
        let json = """
        {
            "count": 100,
            "next": "https://api.example.com/listings/?page=2",
            "previous": null,
            "results": [
                {
                    "id": 1,
                    "title": "Card 1",
                    "description": null,
                    "price": "50.00",
                    "current_bid": null,
                    "buy_now_price": null,
                    "condition": "nm",
                    "condition_display": "Near Mint",
                    "listing_type": "fixed",
                    "status": "active",
                    "image_1": null,
                    "image_2": null,
                    "image_3": null,
                    "image_4": null,
                    "seller": {
                        "username": "seller1",
                        "avatar_url": null,
                        "rating": 4.0,
                        "rating_count": 5,
                        "is_verified": false
                    },
                    "category": null,
                    "item": null,
                    "bid_count": 0,
                    "watch_count": 0,
                    "view_count": 0,
                    "is_watched": null,
                    "end_date": null,
                    "created": null,
                    "shipping_price": null,
                    "accepts_offers": false
                }
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(PaginatedResponse<Listing>.self, from: json)

        XCTAssertEqual(response.count, 100)
        XCTAssertNotNil(response.next)
        XCTAssertNil(response.previous)
        XCTAssertEqual(response.results.count, 1)
        XCTAssertEqual(response.results[0].title, "Card 1")
    }
}
