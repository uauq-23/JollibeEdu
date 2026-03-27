import UIKit

extension UIViewController {
    func showError(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: L10n.tr("common.error"), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("common.close"), style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    func showSuccess(title: String = L10n.tr("common.success"), message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("common.ok"), style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }

    func showConfirm(title: String, message: String, confirmTitle: String = L10n.tr("common.confirm"), onConfirm: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: confirmTitle, style: .default) { _ in
            onConfirm()
        })
        present(alert, animated: true)
    }

    func presentLanguagePicker(onChanged: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: L10n.tr("profile.language.title"),
            message: L10n.tr("profile.language.message"),
            preferredStyle: .actionSheet
        )

        AppLanguage.allCases.forEach { language in
            let title = language == AppSettingsManager.shared.language
                ? "\(language.displayName) ✓"
                : language.displayName
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                AppSettingsManager.shared.language = language
                RootRouter.shared.reloadCurrentRoot(animated: false)
                onChanged?()
            })
        }

        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        present(alert, animated: true)
    }

    func presentAppearancePicker(onChanged: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: L10n.tr("profile.appearance.title"),
            message: L10n.tr("profile.appearance.message"),
            preferredStyle: .actionSheet
        )

        AppAppearanceMode.allCases.forEach { mode in
            let title = mode == AppSettingsManager.shared.appearanceMode
                ? "\(mode.displayName) ✓"
                : mode.displayName
            alert.addAction(UIAlertAction(title: title, style: .default) { _ in
                AppSettingsManager.shared.appearanceMode = mode
                RootRouter.shared.reloadCurrentRoot(animated: false)
                onChanged?()
            })
        }

        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        present(alert, animated: true)
    }

    func presentAppSettingsSheet(includeLogout: Bool = false, onLogout: (() -> Void)? = nil) {
        let alert = UIAlertController(
            title: L10n.tr("settings.title"),
            message: L10n.tr("settings.message"),
            preferredStyle: .actionSheet
        )

        alert.addAction(UIAlertAction(title: L10n.tr("settings.language"), style: .default) { [weak self] _ in
            self?.presentLanguagePicker()
        })
        alert.addAction(UIAlertAction(title: L10n.tr("settings.appearance"), style: .default) { [weak self] _ in
            self?.presentAppearancePicker()
        })
        if includeLogout {
            alert.addAction(UIAlertAction(title: L10n.tr("profile.menu.logout"), style: .destructive) { _ in
                onLogout?()
            })
        }
        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        present(alert, animated: true)
    }
}
