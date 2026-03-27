import UIKit

enum AppTheme {
    static var brandOrange: UIColor { UIColor(hex: "#EA580C") }
    static var brandOrangeDark: UIColor { UIColor(hex: "#C2410C") }
    static var warmBackground: UIColor { dynamicColor(light: "#F8F4EE", dark: "#111827") }
    static var cardBackground: UIColor { dynamicColor(light: "#FFFFFF", dark: "#1F2937") }
    static var textPrimary: UIColor { dynamicColor(light: "#1F2937", dark: "#F9FAFB") }
    static var textSecondary: UIColor { dynamicColor(light: "#6B7280", dark: "#D1D5DB") }
    static var successGreen: UIColor { UIColor(hex: "#16A34A") }
    static var warningYellow: UIColor { UIColor(hex: "#F59E0B") }
    static var dangerRed: UIColor { UIColor(hex: "#DC2626") }
    static var softBorder: UIColor { dynamicColor(light: "#E5E7EB", dark: "#374151") }
    static var mutedOrange: UIColor { dynamicColor(light: "#FED7AA", dark: "#7C2D12") }

    static let cardCornerRadius: CGFloat = 22
    static let buttonCornerRadius: CGFloat = 18
    static let pillCornerRadius: CGFloat = 999
    static let fieldHeight: CGFloat = 52

    static func applyGlobalAppearance() {
        let navigationAppearance = UINavigationBarAppearance()
        navigationAppearance.configureWithOpaqueBackground()
        navigationAppearance.backgroundColor = cardBackground
        navigationAppearance.titleTextAttributes = [
            .foregroundColor: textPrimary,
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        navigationAppearance.largeTitleTextAttributes = [
            .foregroundColor: textPrimary,
            .font: UIFont.boldSystemFont(ofSize: 32)
        ]
        navigationAppearance.shadowColor = UIColor.clear

        UINavigationBar.appearance().standardAppearance = navigationAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationAppearance
        UINavigationBar.appearance().compactAppearance = navigationAppearance
        UINavigationBar.appearance().tintColor = brandOrange

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = cardBackground
        tabAppearance.shadowColor = UIColor.clear
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        UITabBar.appearance().tintColor = brandOrange

        UISegmentedControl.appearance().selectedSegmentTintColor = brandOrange
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        UISegmentedControl.appearance().setTitleTextAttributes([.foregroundColor: brandOrangeDark], for: .normal)
    }

    static func stylePrimaryButton(_ button: UIButton) {
        var configuration = UIButton.Configuration.filled()
        configuration.baseBackgroundColor = brandOrange
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .large
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        button.configuration = configuration
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
    }

    static func styleSecondaryButton(_ button: UIButton) {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = brandOrange
        configuration.background.backgroundColor = cardBackground
        configuration.background.strokeColor = brandOrange
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = buttonCornerRadius
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        button.configuration = configuration
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
    }

    static func styleDestructiveButton(_ button: UIButton) {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = dangerRed
        configuration.background.backgroundColor = cardBackground
        configuration.background.strokeColor = dangerRed
        configuration.background.strokeWidth = 1
        configuration.background.cornerRadius = buttonCornerRadius
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 18, bottom: 14, trailing: 18)
        button.configuration = configuration
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
    }

    static func stylePillButton(_ button: UIButton, selected: Bool) {
        var configuration = UIButton.Configuration.plain()
        configuration.baseForegroundColor = selected ? .white : brandOrangeDark
        configuration.background.backgroundColor = selected ? brandOrange : mutedOrange.withAlphaComponent(0.4)
        configuration.background.cornerRadius = pillCornerRadius
        configuration.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 14, bottom: 8, trailing: 14)
        button.configuration = configuration
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
    }

    static func styleTextField(_ textField: UITextField) {
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.backgroundColor = cardBackground
        textField.textColor = textPrimary
        textField.tintColor = brandOrange
        textField.borderStyle = .none
        textField.layer.cornerRadius = buttonCornerRadius
        textField.layer.borderColor = softBorder.cgColor
        textField.layer.borderWidth = 1
        textField.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        textField.leftViewMode = .always
        textField.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 1))
        textField.rightViewMode = .always
        let hasLocalHeightConstraint = textField.constraints.contains {
            $0.firstAttribute == .height && $0.relation == .equal
        }
        if !hasLocalHeightConstraint {
            NSLayoutConstraint.activate([
                textField.heightAnchor.constraint(equalToConstant: fieldHeight)
            ])
        }
    }

    static func applyCardShadow(to view: UIView) {
        view.layer.shadowColor = UIColor.black.withAlphaComponent(0.12).cgColor
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 18
        view.layer.shadowOffset = CGSize(width: 0, height: 10)
    }

    static func applyWindowAppearance(to window: UIWindow?) {
        guard let window else { return }
        window.overrideUserInterfaceStyle = AppSettingsManager.shared.appearanceMode.interfaceStyle
        window.backgroundColor = warmBackground
        applyGlobalAppearance()
    }

    private static func dynamicColor(light: String, dark: String) -> UIColor {
        UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

extension UIColor {
    convenience init(hex: String) {
        let cleaned = hex.replacingOccurrences(of: "#", with: "")
        var value: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&value)

        let red = CGFloat((value >> 16) & 0xFF) / 255
        let green = CGFloat((value >> 8) & 0xFF) / 255
        let blue = CGFloat(value & 0xFF) / 255
        self.init(red: red, green: green, blue: blue, alpha: 1)
    }
}
