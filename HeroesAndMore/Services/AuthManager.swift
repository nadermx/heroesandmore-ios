import Foundation
import SwiftUI

@MainActor
class AuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Profile?
    @Published var isLoading = false
    @Published var error: String?

    func checkStoredCredentials() {
        Task {
            if let _ = await KeychainService.shared.get(key: Config.accessTokenKey) {
                await fetchCurrentUser()
            }
        }
    }

    func login(username: String, password: String) async -> Bool {
        isLoading = true
        error = nil

        do {
            let request = LoginRequest(username: username, password: password)
            let tokens: AuthTokens = try await APIClient.shared.request(
                path: "/auth/token/",
                method: .post,
                body: request
            )

            await KeychainService.shared.set(key: Config.accessTokenKey, value: tokens.access)
            await KeychainService.shared.set(key: Config.refreshTokenKey, value: tokens.refresh)

            await fetchCurrentUser()
            isLoading = false
            return true
        } catch let apiError as APIError {
            error = apiError.errorDescription
            isLoading = false
            return false
        } catch {
            self.error = "Login failed. Please try again."
            isLoading = false
            return false
        }
    }

    func register(username: String, email: String, password: String, passwordConfirm: String) async -> Bool {
        isLoading = true
        error = nil

        do {
            let request = RegisterRequest(
                username: username,
                email: email,
                password: password,
                passwordConfirm: passwordConfirm
            )

            let tokens: AuthTokens = try await APIClient.shared.request(
                path: "/accounts/register/",
                method: .post,
                body: request
            )

            await KeychainService.shared.set(key: Config.accessTokenKey, value: tokens.access)
            await KeychainService.shared.set(key: Config.refreshTokenKey, value: tokens.refresh)

            await fetchCurrentUser()
            isLoading = false
            return true
        } catch let apiError as APIError {
            error = apiError.errorDescription
            isLoading = false
            return false
        } catch {
            self.error = "Registration failed. Please try again."
            isLoading = false
            return false
        }
    }

    func logout() {
        Task {
            await KeychainService.shared.delete(key: Config.accessTokenKey)
            await KeychainService.shared.delete(key: Config.refreshTokenKey)
            await KeychainService.shared.delete(key: Config.userIdKey)
        }
        isAuthenticated = false
        currentUser = nil
    }

    func fetchCurrentUser() async {
        do {
            let profile: Profile = try await APIClient.shared.request(path: "/accounts/me/")
            currentUser = profile
            isAuthenticated = true
        } catch {
            // Token might be invalid
            logout()
        }
    }

    func updateProfile(bio: String?, location: String?, website: String?) async -> Bool {
        struct UpdateRequest: Codable {
            let bio: String?
            let location: String?
            let website: String?
        }

        do {
            let request = UpdateRequest(bio: bio, location: location, website: website)
            let profile: Profile = try await APIClient.shared.request(
                path: "/accounts/me/",
                method: .patch,
                body: request
            )
            currentUser = profile
            return true
        } catch {
            self.error = "Failed to update profile"
            return false
        }
    }

    func changePassword(oldPassword: String, newPassword: String, confirmPassword: String) async -> Bool {
        struct PasswordRequest: Codable {
            let oldPassword: String
            let newPassword: String
            let newPasswordConfirm: String

            enum CodingKeys: String, CodingKey {
                case oldPassword = "old_password"
                case newPassword = "new_password"
                case newPasswordConfirm = "new_password_confirm"
            }
        }

        do {
            try await APIClient.shared.requestVoid(
                path: "/accounts/me/password/",
                method: .post,
                body: PasswordRequest(
                    oldPassword: oldPassword,
                    newPassword: newPassword,
                    newPasswordConfirm: confirmPassword
                )
            )
            return true
        } catch let apiError as APIError {
            error = apiError.errorDescription
            return false
        } catch {
            self.error = "Failed to change password"
            return false
        }
    }

    // MARK: - Google OAuth

    func loginWithGoogle(idToken: String) async -> Bool {
        isLoading = true
        error = nil

        struct GoogleAuthRequest: Codable {
            let idToken: String

            enum CodingKeys: String, CodingKey {
                case idToken = "id_token"
            }
        }

        do {
            let tokens: AuthTokens = try await APIClient.shared.request(
                path: "/auth/google/",
                method: .post,
                body: GoogleAuthRequest(idToken: idToken)
            )

            await KeychainService.shared.set(key: Config.accessTokenKey, value: tokens.access)
            await KeychainService.shared.set(key: Config.refreshTokenKey, value: tokens.refresh)

            await fetchCurrentUser()
            isLoading = false
            return true
        } catch let apiError as APIError {
            error = apiError.errorDescription
            isLoading = false
            return false
        } catch {
            self.error = "Google sign-in failed. Please try again."
            isLoading = false
            return false
        }
    }

    // MARK: - Apple Sign In

    func loginWithApple(identityToken: String, firstName: String = "", lastName: String = "") async -> Bool {
        isLoading = true
        error = nil

        struct AppleAuthRequest: Codable {
            let idToken: String
            let firstName: String
            let lastName: String

            enum CodingKeys: String, CodingKey {
                case idToken = "id_token"
                case firstName = "first_name"
                case lastName = "last_name"
            }
        }

        do {
            let tokens: AuthTokens = try await APIClient.shared.request(
                path: "/auth/apple/",
                method: .post,
                body: AppleAuthRequest(idToken: identityToken, firstName: firstName, lastName: lastName)
            )

            await KeychainService.shared.set(key: Config.accessTokenKey, value: tokens.access)
            await KeychainService.shared.set(key: Config.refreshTokenKey, value: tokens.refresh)

            await fetchCurrentUser()
            isLoading = false
            return true
        } catch let apiError as APIError {
            error = apiError.errorDescription
            isLoading = false
            return false
        } catch {
            self.error = "Apple sign-in failed. Please try again."
            isLoading = false
            return false
        }
    }

    // MARK: - Password Reset

    func requestPasswordReset(email: String) async -> Bool {
        struct ResetRequest: Codable {
            let email: String
        }

        do {
            try await APIClient.shared.requestVoid(
                path: "/auth/password/reset/",
                method: .post,
                body: ResetRequest(email: email)
            )
            return true
        } catch let apiError as APIError {
            error = apiError.errorDescription
            return false
        } catch {
            self.error = "Failed to send reset email"
            return false
        }
    }

    func confirmPasswordReset(uid: String, token: String, newPassword: String, confirmPassword: String) async -> Bool {
        struct ConfirmRequest: Codable {
            let uid: String
            let token: String
            let newPassword: String
            let newPasswordConfirm: String

            enum CodingKeys: String, CodingKey {
                case uid, token
                case newPassword = "new_password"
                case newPasswordConfirm = "new_password_confirm"
            }
        }

        do {
            try await APIClient.shared.requestVoid(
                path: "/auth/password/reset/confirm/",
                method: .post,
                body: ConfirmRequest(
                    uid: uid,
                    token: token,
                    newPassword: newPassword,
                    newPasswordConfirm: confirmPassword
                )
            )
            return true
        } catch let apiError as APIError {
            error = apiError.errorDescription
            return false
        } catch {
            self.error = "Failed to reset password"
            return false
        }
    }

    // MARK: - Notification Settings

    func getNotificationSettings() async throws -> NotificationSettings {
        return try await APIClient.shared.request(path: "/accounts/me/notifications/")
    }

    func updateNotificationSettings(
        emailNotifications: Bool? = nil,
        pushNewBid: Bool? = nil,
        pushOutbid: Bool? = nil,
        pushOffer: Bool? = nil,
        pushOrderShipped: Bool? = nil,
        pushMessage: Bool? = nil,
        pushPriceAlert: Bool? = nil
    ) async throws -> NotificationSettings {
        struct UpdateRequest: Codable {
            let emailNotifications: Bool?
            let pushNewBid: Bool?
            let pushOutbid: Bool?
            let pushOffer: Bool?
            let pushOrderShipped: Bool?
            let pushMessage: Bool?
            let pushPriceAlert: Bool?

            enum CodingKeys: String, CodingKey {
                case emailNotifications = "email_notifications"
                case pushNewBid = "push_new_bid"
                case pushOutbid = "push_outbid"
                case pushOffer = "push_offer"
                case pushOrderShipped = "push_order_shipped"
                case pushMessage = "push_message"
                case pushPriceAlert = "push_price_alert"
            }
        }

        return try await APIClient.shared.request(
            path: "/accounts/me/notifications/",
            method: .patch,
            body: UpdateRequest(
                emailNotifications: emailNotifications,
                pushNewBid: pushNewBid,
                pushOutbid: pushOutbid,
                pushOffer: pushOffer,
                pushOrderShipped: pushOrderShipped,
                pushMessage: pushMessage,
                pushPriceAlert: pushPriceAlert
            )
        )
    }

    // MARK: - Avatar

    func uploadAvatar(imageData: Data) async throws -> Profile {
        return try await APIClient.shared.upload(
            path: "/accounts/me/avatar/",
            imageData: imageData,
            filename: "avatar.jpg"
        )
    }

    // MARK: - Recently Viewed

    func getRecentlyViewed(page: Int = 1) async throws -> PaginatedResponse<Listing> {
        return try await APIClient.shared.request(
            path: "/accounts/me/recently-viewed/",
            queryItems: [URLQueryItem(name: "page", value: String(page))]
        )
    }

    func clearRecentlyViewed() async throws {
        try await APIClient.shared.requestVoid(
            path: "/accounts/me/recently-viewed/clear/",
            method: .delete
        )
    }

    // MARK: - Device Token (Push Notifications)

    func registerDeviceToken(token: String, platform: String = "ios") async throws {
        struct TokenRequest: Codable {
            let token: String
            let platform: String
        }

        try await APIClient.shared.requestVoid(
            path: "/accounts/me/device/",
            method: .post,
            body: TokenRequest(token: token, platform: platform)
        )
    }

    func removeDeviceToken(token: String) async throws {
        struct TokenRequest: Codable {
            let token: String
        }

        try await APIClient.shared.requestVoid(
            path: "/accounts/me/device/",
            method: .delete,
            body: TokenRequest(token: token)
        )
    }
}
