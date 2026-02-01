import Foundation

struct ScanResult: Codable, Identifiable {
    let id: Int
    let image: String
    let status: String
    let matches: [ScanMatch]
    let created: Date?

    enum CodingKeys: String, CodingKey {
        case id, image, status, matches, created
    }
}

struct ScanMatch: Codable, Identifiable {
    var id: Int { priceGuideItemId }
    let priceGuideItemId: Int
    let name: String
    let imageUrl: String?
    let confidence: Double
    let averagePrice: String?

    enum CodingKeys: String, CodingKey {
        case name, confidence
        case priceGuideItemId = "price_guide_item_id"
        case imageUrl = "image_url"
        case averagePrice = "average_price"
    }

    var confidencePercent: Int {
        Int(confidence * 100)
    }
}

struct ScanSession: Codable, Identifiable {
    let id: Int
    let name: String?
    let scanCount: Int
    let created: Date?
    let scans: [ScanResult]?

    enum CodingKeys: String, CodingKey {
        case id, name, scans, created
        case scanCount = "scan_count"
    }
}
