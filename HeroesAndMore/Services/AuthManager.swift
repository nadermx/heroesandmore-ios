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
}
