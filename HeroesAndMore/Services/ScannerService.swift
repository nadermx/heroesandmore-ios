import Foundation
import UIKit

actor ScannerService {
    static let shared = ScannerService()

    private init() {}

    // MARK: - Scanning

    func scanImage(image: UIImage) async throws -> ScanResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidResponse
        }

        return try await APIClient.shared.upload(
            path: "/scanner/scan/",
            imageData: imageData,
            imageName: "scan_\(Date().timeIntervalSince1970).jpg"
        )
    }

    // MARK: - Scan History

    func getScans(page: Int = 1) async throws -> PaginatedResponse<ScanResult> {
        return try await APIClient.shared.request(
            path: "/scanner/scans/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func getScan(id: Int) async throws -> ScanResult {
        return try await APIClient.shared.request(path: "/scanner/scans/\(id)/")
    }

    func deleteScan(id: Int) async throws {
        try await APIClient.shared.requestVoid(
            path: "/scanner/scans/\(id)/",
            method: .delete
        )
    }

    // MARK: - Scan Sessions

    func getSessions(page: Int = 1) async throws -> PaginatedResponse<ScanSession> {
        return try await APIClient.shared.request(
            path: "/scanner/sessions/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func createSession(name: String?) async throws -> ScanSession {
        struct CreateRequest: Codable {
            let name: String?
        }

        return try await APIClient.shared.request(
            path: "/scanner/sessions/",
            method: .post,
            body: CreateRequest(name: name)
        )
    }

    func getSession(id: Int) async throws -> ScanSession {
        return try await APIClient.shared.request(path: "/scanner/sessions/\(id)/")
    }

    func addScanToSession(sessionId: Int, image: UIImage) async throws -> ScanResult {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw APIError.invalidResponse
        }

        return try await APIClient.shared.upload(
            path: "/scanner/sessions/\(sessionId)/scan/",
            imageData: imageData,
            imageName: "scan_\(Date().timeIntervalSince1970).jpg"
        )
    }
}
