import UIKit

final class ChangePasswordViewController: AuthenticatedStackViewController {
    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var currentPasswordField: UITextField!
    @IBOutlet private weak var newPasswordField: UITextField!
    @IBOutlet private weak var confirmPasswordField: UITextField!
    @IBOutlet private weak var feedbackLabel: UILabel!
    @IBOutlet private weak var submitButton: UIButton!

    override func buildContent() {
        title = L10n.tr("auth.changePassword.title")
        navigationItem.largeTitleDisplayMode = .never

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        currentPasswordField.applyAppStyle(placeholder: L10n.tr("auth.changePassword.current.placeholder"), secure: true)
        newPasswordField.applyAppStyle(placeholder: L10n.tr("auth.changePassword.new.placeholder"), secure: true)
        confirmPasswordField.applyAppStyle(placeholder: L10n.tr("auth.changePassword.confirm.placeholder"), secure: true)

        feedbackLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        feedbackLabel.numberOfLines = 0
        feedbackLabel.textColor = AppTheme.textSecondary

        submitButton.applyPrimaryStyle()
        submitButton.setTitle(L10n.tr("auth.changePassword.button"), for: .normal)
        submitButton.addAction(UIAction { [weak self] _ in
            self?.submitChange()
        }, for: .touchUpInside)
    }

    private func submitChange() {
        submitButton.isEnabled = false
        submitButton.setTitle(L10n.tr("auth.changePassword.loading"), for: .normal)
        Task { @MainActor in
            defer {
                submitButton.isEnabled = true
                submitButton.setTitle(L10n.tr("auth.changePassword.button"), for: .normal)
            }

            do {
                try await AuthService.shared.changePassword(
                    currentPassword: currentPasswordField.text ?? "",
                    newPassword: newPasswordField.text ?? "",
                    confirmPassword: confirmPasswordField.text ?? ""
                )
                feedbackLabel.textColor = AppTheme.successGreen
                feedbackLabel.text = L10n.tr("auth.changePassword.feedbackSuccess")
                showSuccess(message: L10n.tr("auth.changePassword.alertSuccess")) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            } catch {
                feedbackLabel.textColor = AppTheme.dangerRed
                feedbackLabel.text = error.localizedDescription
            }
        }
    }
}
