import Foundation

actor CollectionService {
    static let shared = CollectionService()

    private init() {}

    // MARK: - Collections

    func getMyCollections(page: Int = 1) async throws -> PaginatedResponse<Collection> {
        return try await APIClient.shared.request(
            path: "/collections/mine/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func getPublicCollections(page: Int = 1, search: String? = nil) async throws -> PaginatedResponse<Collection> {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]
        if let search = search, !search.isEmpty {
            queryItems.append(URLQueryItem(name: "search", value: search))
        }

        return try await APIClient.shared.request(
            path: "/collections/public/",
            queryItems: queryItems
        )
    }

    func getCollection(id: Int) async throws -> CollectionDetail {
        return try await APIClient.shared.request(path: "/collections/\(id)/")
    }

    func createCollection(name: String, description: String?, isPublic: Bool) async throws -> Collection {
        struct CreateRequest: Codable {
            let name: String
            let description: String?
            let isPublic: Bool

            enum CodingKeys: String, CodingKey {
                case name, description
                case isPublic = "is_public"
            }
        }

        return try await APIClient.shared.request(
            path: "/collections/mine/",
            method: .post,
            body: CreateRequest(name: name, description: description, isPublic: isPublic)
        )
    }

    func updateCollection(id: Int, name: String?, description: String?, isPublic: Bool?) async throws -> Collection {
        struct UpdateRequest: Codable {
            let name: String?
            let description: String?
            let isPublic: Bool?

            enum CodingKeys: String, CodingKey {
                case name, description
                case isPublic = "is_public"
            }
        }

        return try await APIClient.shared.request(
            path: "/collections/\(id)/",
            method: .patch,
            body: UpdateRequest(name: name, description: description, isPublic: isPublic)
        )
    }

    func deleteCollection(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/collections/\(id)/",
            method: .delete
        )
    }

    // MARK: - Collection Items

    func getCollectionItems(collectionId: Int, page: Int = 1) async throws -> PaginatedResponse<CollectionItem> {
        return try await APIClient.shared.request(
            path: "/collections/\(collectionId)/items/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func addItemToCollection(
        collectionId: Int,
        priceGuideItemId: Int?,
        customName: String?,
        grade: String?,
        gradeCompany: String?,
        certNumber: String?,
        purchasePrice: String?,
        purchaseDate: String?,
        notes: String?
    ) async throws -> CollectionItem {
        struct AddItemRequest: Codable {
            let priceGuideItemId: Int?
            let customName: String?
            let grade: String?
            let gradeCompany: String?
            let certNumber: String?
            let purchasePrice: String?
            let purchaseDate: String?
            let notes: String?

            enum CodingKeys: String, CodingKey {
                case grade, notes
                case priceGuideItemId = "price_guide_item_id"
                case customName = "custom_name"
                case gradeCompany = "grade_company"
                case certNumber = "cert_number"
                case purchasePrice = "purchase_price"
                case purchaseDate = "purchase_date"
            }
        }

        return try await APIClient.shared.request(
            path: "/collections/\(collectionId)/items/",
            method: .post,
            body: AddItemRequest(
                priceGuideItemId: priceGuideItemId,
                customName: customName,
                grade: grade,
                gradeCompany: gradeCompany,
                certNumber: certNumber,
                purchasePrice: purchasePrice,
                purchaseDate: purchaseDate,
                notes: notes
            )
        )
    }

    func removeItemFromCollection(collectionId: Int, itemId: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/collections/\(collectionId)/items/\(itemId)/",
            method: .delete
        )
    }

    // MARK: - Collection Value

    func getCollectionValue(id: Int) async throws -> ValueSummary {
        return try await APIClient.shared.request(path: "/collections/\(id)/value/")
    }

    func getCollectionValueHistory(id: Int) async throws -> [ValueSnapshot] {
        return try await APIClient.shared.request(path: "/collections/\(id)/value_history/")
    }

    // MARK: - Export / Import

    func exportCollection(id: Int, format: String = "json") async throws -> Data {
        // Returns raw data for the export file
        return try await APIClient.shared.requestRaw(
            path: "/collections/\(id)/export/",
            queryItems: [URLQueryItem(name: "export_format", value: format)]
        )
    }

    func importCollection(fileData: Data, fileName: String, collectionName: String? = nil) async throws -> ImportResult {
        return try await APIClient.shared.uploadFile(
            path: "/collections/import/",
            fileData: fileData,
            fileName: fileName,
            additionalFields: collectionName != nil ? ["name": collectionName!] : nil
        )
    }
}
