import XCTest
@testable import HeroesAndMore

final class CollectionServiceTests: XCTestCase {

    // MARK: - Model Tests

    func testCollectionDecoding() throws {
        let json = """
        {
            "id": 1,
            "name": "My Baseball Cards",
            "description": "Collection of vintage baseball cards",
            "is_public": true,
            "cover_image": "https://example.com/cover.jpg",
            "item_count": 25,
            "total_value": "5000.00",
            "created": "2026-01-01T00:00:00Z",
            "updated": "2026-01-15T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let collection = try decoder.decode(Collection.self, from: json)

        XCTAssertEqual(collection.id, 1)
        XCTAssertEqual(collection.name, "My Baseball Cards")
        XCTAssertTrue(collection.isPublic)
        XCTAssertEqual(collection.itemCount, 25)
        XCTAssertEqual(collection.totalValue, "5000.00")
    }

    func testCollectionItemDecoding() throws {
        let json = """
        {
            "id": 1,
            "price_guide_item": {
                "id": 100,
                "name": "Mickey Mantle 1952 Topps",
                "year": 1952,
                "image_url": "https://example.com/mantle.jpg"
            },
            "custom_name": null,
            "grade": "PSA 8",
            "grade_company": "PSA",
            "cert_number": "12345678",
            "purchase_price": "1500.00",
            "purchase_date": "2025-06-15",
            "current_value": "2500.00",
            "notes": "Great centering",
            "image": null,
            "created": "2025-06-15T10:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            let formatters: [DateFormatter] = [
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    return f
                }(),
                {
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd"
                    return f
                }()
            ]

            for formatter in formatters {
                if let date = formatter.date(from: dateString) {
                    return date
                }
            }

            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }

        let item = try decoder.decode(CollectionItem.self, from: json)

        XCTAssertEqual(item.id, 1)
        XCTAssertEqual(item.grade, "PSA 8")
        XCTAssertEqual(item.gradeCompany, "PSA")
        XCTAssertEqual(item.certNumber, "12345678")
        XCTAssertEqual(item.purchasePrice, "1500.00")
        XCTAssertEqual(item.currentValue, "2500.00")
        XCTAssertEqual(item.displayName, "Mickey Mantle 1952 Topps")
        XCTAssertNotNil(item.priceGuideItem)
    }

    func testCollectionItemWithCustomName() throws {
        let json = """
        {
            "id": 2,
            "price_guide_item": null,
            "custom_name": "My Custom Card",
            "grade": "Raw",
            "grade_company": null,
            "cert_number": null,
            "purchase_price": "50.00",
            "purchase_date": null,
            "current_value": null,
            "notes": null,
            "image": null,
            "created": null
        }
        """.data(using: .utf8)!

        let item = try JSONDecoder().decode(CollectionItem.self, from: json)

        XCTAssertEqual(item.id, 2)
        XCTAssertNil(item.priceGuideItem)
        XCTAssertEqual(item.customName, "My Custom Card")
        XCTAssertEqual(item.displayName, "My Custom Card")
    }

    func testValueSnapshotDecoding() throws {
        let json = """
        {
            "date": "2026-01-15",
            "value": "5250.00"
        }
        """.data(using: .utf8)!

        let snapshot = try JSONDecoder().decode(ValueSnapshot.self, from: json)

        XCTAssertEqual(snapshot.date, "2026-01-15")
        XCTAssertEqual(snapshot.value, "5250.00")
        XCTAssertEqual(snapshot.id, "2026-01-15")
    }

    func testValueSummaryDecoding() throws {
        let json = """
        {
            "total_value": "5000.00",
            "total_cost": "3500.00",
            "total_gain_loss": "1500.00",
            "gain_loss_percent": "42.86",
            "item_count": 25,
            "last_updated": "2026-01-15T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let summary = try decoder.decode(ValueSummary.self, from: json)

        XCTAssertEqual(summary.totalValue, "5000.00")
        XCTAssertEqual(summary.totalCost, "3500.00")
        XCTAssertEqual(summary.totalGainLoss, "1500.00")
        XCTAssertEqual(summary.gainLossPercent, "42.86")
        XCTAssertEqual(summary.itemCount, 25)
    }

    func testImportResultDecoding() throws {
        let json = """
        {
            "collection_id": 5,
            "collection_name": "Imported Collection",
            "items_imported": 15,
            "items_total": 20
        }
        """.data(using: .utf8)!

        let result = try JSONDecoder().decode(ImportResult.self, from: json)

        XCTAssertEqual(result.collectionId, 5)
        XCTAssertEqual(result.collectionName, "Imported Collection")
        XCTAssertEqual(result.itemsImported, 15)
        XCTAssertEqual(result.itemsTotal, 20)
    }

    func testCollectionDetailDecoding() throws {
        let json = """
        {
            "id": 1,
            "name": "Premium Collection",
            "description": "High-end cards",
            "is_public": true,
            "cover_image": null,
            "owner": {
                "username": "collector1",
                "avatar_url": null
            },
            "item_count": 10,
            "total_value": "10000.00",
            "items": [],
            "value_history": [
                {"date": "2026-01-14", "value": "9500.00"},
                {"date": "2026-01-15", "value": "10000.00"}
            ],
            "created": "2025-12-01T00:00:00Z",
            "updated": "2026-01-15T00:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let detail = try decoder.decode(CollectionDetail.self, from: json)

        XCTAssertEqual(detail.id, 1)
        XCTAssertEqual(detail.name, "Premium Collection")
        XCTAssertEqual(detail.owner.username, "collector1")
        XCTAssertEqual(detail.totalValue, "10000.00")
        XCTAssertEqual(detail.valueHistory?.count, 2)
    }
}
