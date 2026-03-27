import UIKit

final class ForgotPasswordViewController: BaseStackContainerViewController {
    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var introCardView: UIView!
    @IBOutlet private weak var stepOneCardView: UIView!
    @IBOutlet private weak var resetContainer: UIView!
    @IBOutlet private weak var stepLabel: UILabel!
    @IBOutlet private weak var emailField: UITextField!
    @IBOutlet private weak var newPasswordField: UITextField!
    @IBOutlet private weak var confirmPasswordField: UITextField!
    @IBOutlet private weak var verifyButton: UIButton!
    @IBOutlet private weak var submitButton: UIButton!
    @IBOutlet private weak var statusLabel: UILabel!

    private var verifiedEmail: String?

    override func buildContent() {
        title = L10n.tr("auth.forgot.title")
        navigationItem.largeTitleDisplayMode = .never

        introCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        stepOneCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        resetContainer.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        emailField.applyAppStyle(placeholder: L10n.tr("auth.forgot.email.placeholder"), keyboard: .emailAddress)
        newPasswordField.applyAppStyle(placeholder: L10n.tr("auth.forgot.newPassword.placeholder"), secure: true)
        confirmPasswordField.applyAppStyle(placeholder: L10n.tr("auth.forgot.confirmPassword.placeholder"), secure: true)

        stepLabel.font = UIFont.boldSystemFont(ofSize: 18)
        stepLabel.textColor = AppTheme.textPrimary
        stepLabel.numberOfLines = 0
        stepLabel.text = L10n.tr("auth.forgot.step1")

        statusLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        statusLabel.numberOfLines = 0
        statusLabel.textColor = AppTheme.textSecondary

        verifyButton.applyPrimaryStyle()
        verifyButton.setTitle(L10n.tr("auth.forgot.verify.button"), for: .normal)
        verifyButton.addAction(UIAction { [weak self] _ in
            self?.verifyEmail()
        }, for: .touchUpInside)

        submitButton.applyPrimaryStyle()
        submitButton.setTitle(L10n.tr("auth.forgot.submit.button"), for: .normal)
        submitButton.addAction(UIAction { [weak self] _ in
            self?.submitReset()
        }, for: .touchUpInside)
        resetContainer.isHidden = true
    }

    private func verifyEmail() {
        verifyButton.isEnabled = false
        verifyButton.setTitle(L10n.tr("auth.forgot.verify.loading"), for: .normal)
        Task { @MainActor in
            defer {
                verifyButton.isEnabled = true
                verifyButton.setTitle(L10n.tr("auth.forgot.verify.button"), for: .normal)
            }

            do {
                let exists = try await AuthService.shared.checkEmail(email: emailField.text ?? "")
                guard exists else {
                    statusLabel.textColor = AppTheme.dangerRed
                    statusLabel.text = L10n.tr("auth.forgot.emailNotFound")
                    return
                }
                verifiedEmail = emailField.text
                statusLabel.textColor = AppTheme.successGreen
                statusLabel.text = L10n.tr("auth.forgot.emailVerified")
                stepLabel.text = L10n.tr("auth.forgot.step2")
                resetContainer.isHidden = false
            } catch {
                statusLabel.textColor = AppTheme.dangerRed
                statusLabel.text = error.localizedDescription
            }
        }
    }

    private func submitReset() {
        guard let verifiedEmail else {
            statusLabel.textColor = AppTheme.dangerRed
            statusLabel.text = L10n.tr("auth.forgot.verifyFirst")
            return
        }

        submitButton.isEnabled = false
        submitButton.setTitle(L10n.tr("auth.forgot.submit.loading"), for: .normal)
        Task { @MainActor in
            defer {
                submitButton.isEnabled = true
                submitButton.setTitle(L10n.tr("auth.forgot.submit.button"), for: .normal)
            }

            do {
                try await AuthService.shared.resetPassword(
                    email: verifiedEmail,
                    newPassword: newPasswordField.text ?? "",
                    confirmPassword: confirmPasswordField.text ?? ""
                )
                showSuccess(message: L10n.tr("auth.forgot.resetSuccess")) { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            } catch {
                statusLabel.textColor = AppTheme.dangerRed
                statusLabel.text = error.localizedDescription
            }
        }
    }
}
