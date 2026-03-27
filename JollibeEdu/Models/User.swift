import Foundation

struct User: Codable, Equatable {
    let id: String
    var full_name: String
    var email: String
    var role: String
    var username: String? = nil
    var avatar: String?
    var created_at: String?

    var displayName: String {
        full_name
    }

    var displayUsername: String {
        username ?? email.components(separatedBy: "@").first ?? full_name.replacingOccurrences(of: " ", with: "").lowercased()
    }

    var initials: String {
        AppFormatting.initials(from: full_name)
    }
}
