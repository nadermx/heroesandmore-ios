import Foundation

actor CategoryService {
    static let shared = CategoryService()

    private init() {}

    // MARK: - Categories

    func getCategories() async throws -> [Category] {
        return try await APIClient.shared.request(path: "/items/categories/")
    }

    func getCategory(id: Int) async throws -> Category {
        return try await APIClient.shared.request(path: "/items/categories/\(id)/")
    }

    // MARK: - Search

    func search(query: String, page: Int = 1) async throws -> SearchResult {
        return try await APIClient.shared.request(
            path: "/items/search/",
            queryItems: [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "page", value: String(page))
            ]
        )
    }

    func autocomplete(query: String) async throws -> AutocompleteResult {
        return try await APIClient.shared.request(
            path: "/items/autocomplete/",
            queryItems: [URLQueryItem(name: "q", value: query)]
        )
    }
}
