import Foundation

extension Notification.Name {
    static let sessionDidChange = Notification.Name("sessionDidChange")
}

final class SessionManager {
    static let shared = SessionManager()

    private let defaults = UserDefaults.standard
    private let coreDataManager = CoreDataManager.shared
    private let tokenKey = "session.token"
    private let userKey = "session.user"
    private let rememberedEmailKey = "session.rememberedEmail"

    private init() {
        migrateLegacyDefaultsIfNeeded()
    }

    var token: String? {
        coreDataManager.currentSession()?.token
    }

    var currentUser: User? {
        return coreDataManager.currentSession()?.user
    }

    var rememberedEmail: String? {
        coreDataManager.fetchRememberedEmail()
    }

    var isLoggedIn: Bool {
        token != nil && currentUser != nil
    }

    var isAdmin: Bool {
        currentUser?.role.lowercased() == "admin"
    }

    var isInstructor: Bool {
        currentUser?.role.lowercased() == "instructor"
    }

    var isStudent: Bool {
        currentUser?.role.lowercased() == "student"
    }

    var isLearnerRole: Bool {
        (isStudent || isInstructor) && isLoggedIn
    }

    func saveSession(token: String, user: User, rememberedEmail: String? = nil) {
        coreDataManager.saveSession(token: token, user: user)
        if let rememberedEmail {
            coreDataManager.saveRememberedEmail(rememberedEmail)
        }
        NotificationCenter.default.post(name: .sessionDidChange, object: nil)
    }

    func updateCurrentUser(_ user: User) {
        coreDataManager.updateCurrentSessionUser(user, token: token)
        NotificationCenter.default.post(name: .sessionDidChange, object: nil)
    }

    func storeRememberedEmail(_ email: String?) {
        coreDataManager.saveRememberedEmail(email)
    }

    func clearSession() {
        coreDataManager.clearCurrentSession()
        NotificationCenter.default.post(name: .sessionDidChange, object: nil)
    }

    private func migrateLegacyDefaultsIfNeeded() {
        if coreDataManager.currentSession() == nil,
           let token = defaults.string(forKey: tokenKey),
           let data = defaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            coreDataManager.saveSession(token: token, user: user)
        }

        if coreDataManager.fetchRememberedEmail() == nil {
            coreDataManager.saveRememberedEmail(defaults.string(forKey: rememberedEmailKey))
        }

        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: userKey)
        defaults.removeObject(forKey: rememberedEmailKey)
    }
}
