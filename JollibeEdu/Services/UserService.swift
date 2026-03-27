import Foundation

final class UserService {
    static let shared = UserService()
    private let demoStore = DemoDataStore.shared

    private init() {}

    func getAll(page: Int, limit: Int) async throws -> [User] {
        return try demoStore.allUsers(page: page, limit: limit)
    }

    func getById(id: String) async throws -> User {
        return try demoStore.user(by: id)
    }

    func create(fullName: String, username: String, email: String, password: String, role: String) async throws -> User {
        return try demoStore.createUser(fullName: fullName, username: username, email: email, password: password, role: role)
    }

    func update(id: String, data: [String: String]) async throws -> User {
        return try demoStore.updateUser(id: id, fullName: data["full_name"] ?? "", username: data["username"] ?? "", email: data["email"] ?? "", role: data["role"] ?? "student", password: data["password"])
    }

    func updateProfile(data: [String: String]) async throws -> User {
        let user = try demoStore.updateProfile(fullName: data["full_name"] ?? "", email: data["email"] ?? "")
        SessionManager.shared.updateCurrentUser(user)
        return user
    }

    func resetPassword(userId: String, newPassword: String) async throws {
        try demoStore.resetPassword(for: userId, newPassword: newPassword)
    }

    func delete(id: String) async throws {
        try demoStore.deleteUser(id: id)
    }
}
