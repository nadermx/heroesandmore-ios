import Foundation

struct PriceGuideItem: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let year: Int?
    let category: PriceGuideCategory?
    let imageUrl: String?
    let averagePrice: String?
    let lowPrice: String?
    let highPrice: String?
    let lastSalePrice: String?
    let lastSaleDate: Date?
    let salesCount: Int
    let priceChange30d: String?
    let priceChangePercent30d: String?

    enum CodingKeys: String, CodingKey {
        case id, name, description, year, category
        case imageUrl = "image_url"
        case averagePrice = "average_price"
        case lowPrice = "low_price"
        case highPrice = "high_price"
        case lastSalePrice = "last_sale_price"
        case lastSaleDate = "last_sale_date"
        case salesCount = "sales_count"
        case priceChange30d = "price_change_30d"
        case priceChangePercent30d = "price_change_percent_30d"
    }
}

struct PriceGuideCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
}

struct GradePrice: Codable, Identifiable {
    var id: String { grade }
    let grade: String
    let gradeCompany: String
    let averagePrice: String?
    let lowPrice: String?
    let highPrice: String?
    let salesCount: Int
    let lastSalePrice: String?
    let lastSaleDate: Date?

    enum CodingKeys: String, CodingKey {
        case grade
        case gradeCompany = "grade_company"
        case averagePrice = "average_price"
        case lowPrice = "low_price"
        case highPrice = "high_price"
        case salesCount = "sales_count"
        case lastSalePrice = "last_sale_price"
        case lastSaleDate = "last_sale_date"
    }
}

struct SaleRecord: Codable, Identifiable {
    let id: Int
    let price: String
    let grade: String?
    let gradeCompany: String?
    let source: String
    let saleDate: Date?
    let platform: String?

    enum CodingKeys: String, CodingKey {
        case id, price, grade, source, platform
        case gradeCompany = "grade_company"
        case saleDate = "sale_date"
    }
}

struct PriceHistory: Codable, Identifiable {
    var id: String { date }
    let date: String
    let averagePrice: String
    let salesCount: Int

    enum CodingKeys: String, CodingKey {
        case date
        case averagePrice = "average_price"
        case salesCount = "sales_count"
    }
}

struct TrendingItem: Codable, Identifiable {
    let id: Int
    let name: String
    let imageUrl: String?
    let currentPrice: String?
    let priceChange: String?
    let priceChangePercent: String?
    let trend: String // "up", "down", "stable"

    enum CodingKeys: String, CodingKey {
        case id, name, trend
        case imageUrl = "image_url"
        case currentPrice = "current_price"
        case priceChange = "price_change"
        case priceChangePercent = "price_change_percent"
    }
}
