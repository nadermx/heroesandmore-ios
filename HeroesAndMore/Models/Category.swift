import Foundation

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String
    let description: String?
    let imageUrl: String?
    let parentId: Int?
    let children: [Category]?
    let listingsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, children
        case imageUrl = "image_url"
        case parentId = "parent_id"
        case listingsCount = "listings_count"
    }
}

struct SearchResult: Codable {
    let listings: [Listing]
    let priceGuideItems: [PriceGuideItem]
    let collections: [Collection]
    let users: [PublicProfile]

    enum CodingKeys: String, CodingKey {
        case listings, collections, users
        case priceGuideItems = "price_guide_items"
    }
}

struct AutocompleteResult: Codable {
    let suggestions: [AutocompleteSuggestion]
}

struct AutocompleteSuggestion: Codable, Identifiable {
    var id: String { "\(type)-\(value)" }
    let type: String // "listing", "item", "category", "user"
    let value: String
    let label: String
    let imageUrl: String?

    enum CodingKeys: String, CodingKey {
        case type, value, label
        case imageUrl = "image_url"
    }
}
