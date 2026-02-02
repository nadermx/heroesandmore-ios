import XCTest
@testable import HeroesAndMore

final class UserModelTests: XCTestCase {

    // MARK: - User Tests

    func testUserDecoding() throws {
        let json = """
        {
            "id": 1,
            "username": "testuser",
            "email": "test@example.com",
            "date_joined": "2025-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let user = try decoder.decode(User.self, from: json)

        XCTAssertEqual(user.id, 1)
        XCTAssertEqual(user.username, "testuser")
        XCTAssertEqual(user.email, "test@example.com")
        XCTAssertNotNil(user.dateJoined)
    }

    // MARK: - Profile Tests

    func testProfileDecoding() throws {
        let json = """
        {
            "id": 1,
            "username": "seller1",
            "email": "seller@example.com",
            "avatar": "avatars/seller1.jpg",
            "avatar_url": "https://example.com/avatars/seller1.jpg",
            "bio": "Avid collector since 2010",
            "location": "New York, NY",
            "website": "https://mycollection.com",
            "is_seller_verified": true,
            "stripe_account_complete": true,
            "seller_tier": "premium",
            "rating": 4.8,
            "rating_count": 150,
            "total_sales_count": 500,
            "is_public": true,
            "email_notifications": true,
            "created": "2020-01-01T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let profile = try decoder.decode(Profile.self, from: json)

        XCTAssertEqual(profile.id, 1)
        XCTAssertEqual(profile.username, "seller1")
        XCTAssertEqual(profile.bio, "Avid collector since 2010")
        XCTAssertEqual(profile.location, "New York, NY")
        XCTAssertTrue(profile.isSellerVerified)
        XCTAssertTrue(profile.stripeAccountComplete)
        XCTAssertEqual(profile.sellerTier, "premium")
        XCTAssertEqual(profile.rating, 4.8)
        XCTAssertEqual(profile.ratingCount, 150)
        XCTAssertEqual(profile.totalSalesCount, 500)
    }

    func testPublicProfileDecoding() throws {
        let json = """
        {
            "username": "publicuser",
            "avatar_url": "https://example.com/avatar.jpg",
            "bio": "Public profile bio",
            "location": "Los Angeles, CA",
            "website": null,
            "rating": 4.5,
            "rating_count": 50,
            "is_seller_verified": false,
            "total_sales_count": 25,
            "listings_count": 10,
            "created": "2023-06-15T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let profile = try decoder.decode(PublicProfile.self, from: json)

        XCTAssertEqual(profile.username, "publicuser")
        XCTAssertEqual(profile.location, "Los Angeles, CA")
        XCTAssertNil(profile.website)
        XCTAssertFalse(profile.isSellerVerified)
        XCTAssertEqual(profile.listingsCount, 10)
    }

    // MARK: - Auth Token Tests

    func testAuthTokensDecoding() throws {
        let json = """
        {
            "access": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access",
            "refresh": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh"
        }
        """.data(using: .utf8)!

        let tokens = try JSONDecoder().decode(AuthTokens.self, from: json)

        XCTAssertTrue(tokens.access.hasPrefix("eyJ"))
        XCTAssertTrue(tokens.refresh.hasPrefix("eyJ"))
    }

    // MARK: - Notification Settings Tests

    func testNotificationSettingsDecoding() throws {
        let json = """
        {
            "email_notifications": true,
            "push_new_bid": true,
            "push_outbid": true,
            "push_offer": false,
            "push_order_shipped": true,
            "push_message": true,
            "push_price_alert": false
        }
        """.data(using: .utf8)!

        let settings = try JSONDecoder().decode(NotificationSettings.self, from: json)

        XCTAssertTrue(settings.emailNotifications)
        XCTAssertTrue(settings.pushNewBid)
        XCTAssertTrue(settings.pushOutbid)
        XCTAssertFalse(settings.pushOffer)
        XCTAssertTrue(settings.pushOrderShipped)
        XCTAssertTrue(settings.pushMessage)
        XCTAssertFalse(settings.pushPriceAlert)
    }

    // MARK: - Request Encoding Tests

    func testLoginRequestEncoding() throws {
        let request = LoginRequest(username: "testuser", password: "password123")
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode([String: String].self, from: data)

        XCTAssertEqual(decoded["username"], "testuser")
        XCTAssertEqual(decoded["password"], "password123")
    }

    func testRegisterRequestEncoding() throws {
        let request = RegisterRequest(
            username: "newuser",
            email: "new@example.com",
            password: "securepass123",
            passwordConfirm: "securepass123"
        )
        let data = try JSONEncoder().encode(request)
        let decoded = try JSONDecoder().decode([String: String].self, from: data)

        XCTAssertEqual(decoded["username"], "newuser")
        XCTAssertEqual(decoded["email"], "new@example.com")
        XCTAssertEqual(decoded["password"], "securepass123")
        XCTAssertEqual(decoded["password_confirm"], "securepass123")
    }
}
