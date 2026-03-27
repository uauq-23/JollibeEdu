import Foundation

struct AuthPayload: Codable {
    let token: String
    let user: User
}

final class AuthService {
    static let shared = AuthService()
    private let demoStore = DemoDataStore.shared

    private init() {}

    func register(fullName: String, username: String, email: String, password: String, confirmPassword: String) async throws -> AuthPayload {
        guard password == confirmPassword else { throw DemoDataStoreError.passwordMismatch }

        let result = try demoStore.register(fullName: fullName, username: username, email: email, password: password)
        return AuthPayload(token: result.token, user: result.user)
    }

    func login(identifier: String, password: String) async throws -> AuthPayload {
        let result = try demoStore.login(identifier: identifier, password: password)
        return AuthPayload(token: result.token, user: result.user)
    }

    func getMe() async throws -> User {
        return try demoStore.getCurrentUser()
    }

    func changePassword(currentPassword: String, newPassword: String, confirmPassword: String) async throws {
        guard newPassword == confirmPassword else { throw DemoDataStoreError.passwordMismatch }

        try demoStore.changePassword(currentPassword: currentPassword, newPassword: newPassword)
    }

    func checkEmail(email: String) async throws -> Bool {
        return demoStore.checkEmailExists(email)
    }

    func resetPassword(email: String, newPassword: String, confirmPassword: String) async throws {
        guard newPassword == confirmPassword else { throw DemoDataStoreError.passwordMismatch }

        try demoStore.resetPassword(email: email, newPassword: newPassword)
    }
}
