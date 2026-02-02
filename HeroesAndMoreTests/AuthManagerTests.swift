import XCTest
@testable import HeroesAndMore

final class AuthManagerTests: XCTestCase {

    var authManager: AuthManager!

    @MainActor
    override func setUp() {
        super.setUp()
        authManager = AuthManager()
    }

    override func tearDown() {
        authManager = nil
        super.tearDown()
    }

    // MARK: - Login Tests

    @MainActor
    func testLoginInitialState() {
        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
        XCTAssertFalse(authManager.isLoading)
        XCTAssertNil(authManager.error)
    }

    @MainActor
    func testLoginWithEmptyCredentials() async {
        let success = await authManager.login(username: "", password: "")
        XCTAssertFalse(success)
    }

    // MARK: - Registration Tests

    @MainActor
    func testRegisterWithMismatchedPasswords() async {
        let success = await authManager.register(
            username: "testuser",
            email: "test@test.com",
            password: "password123",
            passwordConfirm: "different"
        )
        XCTAssertFalse(success)
    }

    // MARK: - Password Reset Tests

    @MainActor
    func testRequestPasswordResetWithInvalidEmail() async {
        let success = await authManager.requestPasswordReset(email: "invalid")
        XCTAssertFalse(success)
    }

    // MARK: - Logout Tests

    @MainActor
    func testLogout() {
        // Simulate logged in state
        authManager.isAuthenticated = true

        authManager.logout()

        XCTAssertFalse(authManager.isAuthenticated)
        XCTAssertNil(authManager.currentUser)
    }
}
