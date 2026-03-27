import UIKit

extension Notification.Name {
    static let appSettingsDidChange = Notification.Name("appSettingsDidChange")
}

enum AppLanguage: String, CaseIterable {
    case vietnamese = "vi"
    case english = "en"

    var displayName: String {
        switch self {
        case .vietnamese:
            return L10n.tr("settings.language.vi")
        case .english:
            return L10n.tr("settings.language.en")
        }
    }
}

enum AppAppearanceMode: String, CaseIterable {
    case system
    case light
    case dark

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }

    var displayName: String {
        switch self {
        case .system:
            return L10n.tr("profile.appearance.system")
        case .light:
            return L10n.tr("profile.appearance.light")
        case .dark:
            return L10n.tr("profile.appearance.dark")
        }
    }
}

final class AppSettingsManager {
    static let shared = AppSettingsManager()

    private let defaults = UserDefaults.standard
    private let languageKey = "app.settings.language"
    private let appearanceKey = "app.settings.appearance"

    private init() {
        applyStoredLanguage()
    }

    var language: AppLanguage {
        get {
            AppLanguage(rawValue: defaults.string(forKey: languageKey) ?? AppLanguage.vietnamese.rawValue) ?? .vietnamese
        }
        set {
            defaults.set(newValue.rawValue, forKey: languageKey)
            defaults.set([newValue.rawValue], forKey: "AppleLanguages")
            defaults.synchronize()
            NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
        }
    }

    var appearanceMode: AppAppearanceMode {
        get {
            AppAppearanceMode(rawValue: defaults.string(forKey: appearanceKey) ?? AppAppearanceMode.system.rawValue) ?? .system
        }
        set {
            defaults.set(newValue.rawValue, forKey: appearanceKey)
            defaults.synchronize()
            NotificationCenter.default.post(name: .appSettingsDidChange, object: nil)
        }
    }

    func applyStoredLanguage() {
        defaults.set([language.rawValue], forKey: "AppleLanguages")
        defaults.synchronize()
    }
}
