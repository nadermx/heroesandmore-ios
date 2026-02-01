import Foundation

enum Config {
    // MARK: - API Configuration
    #if DEBUG
    static let apiBaseURL = "http://localhost:8000/api/v1"
    #else
    static let apiBaseURL = "https://www.heroesandmore.com/api/v1"
    #endif

    // MARK: - Keychain Keys
    static let accessTokenKey = "com.heroesandmore.accessToken"
    static let refreshTokenKey = "com.heroesandmore.refreshToken"
    static let userIdKey = "com.heroesandmore.userId"

    // MARK: - App Info
    static let appName = "HeroesAndMore"
    static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    static let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    // MARK: - Pagination
    static let defaultPageSize = 20

    // MARK: - Cache
    static let imageCacheLimit = 100 * 1024 * 1024 // 100 MB
    static let cacheExpirationInterval: TimeInterval = 3600 // 1 hour
}
