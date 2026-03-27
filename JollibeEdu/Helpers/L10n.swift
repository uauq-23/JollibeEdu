import Foundation

enum L10n {
    private static var bundle: Bundle {
        let selectedLanguage = AppSettingsManager.shared.language.rawValue
        if let path = Bundle.main.path(forResource: selectedLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return bundle
        }
        return Bundle.main
    }

    static func tr(_ key: String) -> String {
        bundle.localizedString(forKey: key, value: key, table: nil)
    }

    static func tr(_ key: String, _ arguments: CVarArg...) -> String {
        let format = tr(key)
        return String(format: format, locale: Locale.current, arguments: arguments)
    }

    static func roleName(for role: String) -> String {
        switch role.lowercased() {
        case "student":
            return tr("role.student")
        case "instructor":
            return tr("role.instructor")
        case "admin":
            return tr("role.admin")
        default:
            return role.capitalized
        }
    }

    static func statusName(for status: String) -> String {
        switch status.lowercased() {
        case "student":
            return roleName(for: status)
        case "instructor":
            return roleName(for: status)
        case "admin":
            return roleName(for: status)
        case "published":
            return tr("status.published")
        case "draft":
            return tr("status.draft")
        case "active":
            return tr("status.active")
        case "completed":
            return tr("status.completed")
        default:
            return status.capitalized
        }
    }
}
