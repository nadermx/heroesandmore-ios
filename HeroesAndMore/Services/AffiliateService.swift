import Foundation

actor AffiliateService {
    static let shared = AffiliateService()

    private init() {}

    func join() async throws -> Affiliate {
        return try await APIClient.shared.request(
            path: "/affiliates/join/",
            method: .post
        )
    }

    func getDashboard() async throws -> Affiliate {
        return try await APIClient.shared.request(
            path: "/affiliates/dashboard/"
        )
    }

    func updateSettings(paypalEmail: String) async throws -> Affiliate {
        let body = UpdateAffiliateSettingsRequest(paypalEmail: paypalEmail)
        return try await APIClient.shared.request(
            path: "/affiliates/settings/",
            method: .put,
            body: body
        )
    }

    func getReferrals(page: Int = 1) async throws -> PaginatedResponse<Referral> {
        return try await APIClient.shared.request(
            path: "/affiliates/referrals/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func getCommissions(page: Int = 1, status: String? = nil) async throws -> PaginatedResponse<AffiliateCommission> {
        var queryItems = [URLQueryItem(name: "page", value: String(page))]
        if let status = status {
            queryItems.append(URLQueryItem(name: "status", value: status))
        }
        return try await APIClient.shared.request(
            path: "/affiliates/commissions/",
            queryItems: queryItems
        )
    }

    func getPayouts(page: Int = 1) async throws -> PaginatedResponse<AffiliatePayout> {
        return try await APIClient.shared.request(
            path: "/affiliates/payouts/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }
}
