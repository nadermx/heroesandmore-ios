import Foundation

actor PriceGuideService {
    static let shared = PriceGuideService()

    private init() {}

    // MARK: - Price Guide Items

    func getItems(
        page: Int = 1,
        category: Int? = nil,
        search: String? = nil,
        sort: String? = nil
    ) async throws -> PaginatedResponse<PriceGuideItem> {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]

        if let category = category {
            queryItems.append(URLQueryItem(name: "category", value: String(category)))
        }
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }
        if let sort = sort {
            queryItems.append(URLQueryItem(name: "ordering", value: sort))
        }

        return try await APIClient.shared.request(
            path: "/pricing/items/",
            queryItems: queryItems
        )
    }

    func getItem(id: Int) async throws -> PriceGuideItem {
        return try await APIClient.shared.request(path: "/pricing/items/\(id)/")
    }

    // MARK: - Grade Prices

    func getGradePrices(itemId: Int) async throws -> [GradePrice] {
        return try await APIClient.shared.request(path: "/pricing/items/\(itemId)/grades/")
    }

    // MARK: - Sales History

    func getSales(itemId: Int, page: Int = 1) async throws -> PaginatedResponse<SaleRecord> {
        return try await APIClient.shared.request(
            path: "/pricing/items/\(itemId)/sales/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    // MARK: - Price History (for charts)

    func getPriceHistory(itemId: Int, period: String = "1y") async throws -> [PriceHistory] {
        return try await APIClient.shared.request(
            path: "/pricing/items/\(itemId)/history/",
            queryItems: [URLQueryItem(name: "period", value: period)]
        )
    }

    // MARK: - Trending

    func getTrending() async throws -> [TrendingItem] {
        return try await APIClient.shared.request(path: "/pricing/trending/")
    }
}
