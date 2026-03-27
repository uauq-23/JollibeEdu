import UIKit

final class RegisterViewController: BaseStackContainerViewController {
    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var heroCardView: UIView!
    @IBOutlet private weak var formCardView: UIView!
    @IBOutlet private weak var fullNameField: UITextField!
    @IBOutlet private weak var usernameField: UITextField!
    @IBOutlet private weak var emailField: UITextField!
    @IBOutlet private weak var passwordField: UITextField!
    @IBOutlet private weak var confirmPasswordField: UITextField!
    @IBOutlet private weak var agreementSwitch: UISwitch!
    @IBOutlet private weak var errorLabel: UILabel!
    @IBOutlet private weak var registerButton: UIButton!
    @IBOutlet private weak var loginButton: UIButton!

    override func buildContent() {
        title = L10n.tr("auth.register.title")
        navigationItem.largeTitleDisplayMode = .never

        heroCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        formCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        fullNameField.applyAppStyle(placeholder: L10n.tr("auth.register.fullname.placeholder"))
        fullNameField.autocapitalizationType = .words
        usernameField.applyAppStyle(placeholder: L10n.tr("auth.register.username.placeholder"))
        usernameField.autocapitalizationType = .none
        usernameField.autocorrectionType = .no
        emailField.applyAppStyle(placeholder: L10n.tr("auth.register.email.placeholder"), keyboard: .emailAddress)
        passwordField.applyAppStyle(placeholder: L10n.tr("auth.register.password.placeholder"), secure: true)
        confirmPasswordField.applyAppStyle(placeholder: L10n.tr("auth.register.confirm.placeholder"), secure: true)
        agreementSwitch.onTintColor = AppTheme.brandOrange

        errorLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        errorLabel.textColor = AppTheme.dangerRed
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        registerButton.applyPrimaryStyle()
        registerButton.setTitle(L10n.tr("auth.register.button"), for: .normal)
        registerButton.addAction(UIAction { [weak self] _ in
            self?.submitRegister()
        }, for: .touchUpInside)
        loginButton.applySecondaryOutlineStyle()
        loginButton.setTitle(L10n.tr("auth.register.login"), for: .normal)
        loginButton.addAction(UIAction { [weak self] _ in
            self?.performSegue(withIdentifier: "RegisterShowLogin", sender: self)
        }, for: .touchUpInside)
    }

    private func submitRegister() {
        errorLabel.isHidden = true
        guard agreementSwitch.isOn else {
            errorLabel.text = L10n.tr("auth.register.agreementRequired")
            errorLabel.isHidden = false
            return
        }
        if let validationError = validateForm() {
            errorLabel.text = validationError
            errorLabel.isHidden = false
            return
        }

        registerButton.isEnabled = false
        registerButton.setTitle(L10n.tr("auth.register.loading"), for: .normal)
        Task { @MainActor in
            defer {
                registerButton.isEnabled = true
                registerButton.setTitle(L10n.tr("auth.register.button"), for: .normal)
            }

            do {
                let payload = try await AuthService.shared.register(
                    fullName: fullNameField.text ?? "",
                    username: usernameField.text ?? "",
                    email: emailField.text ?? "",
                    password: passwordField.text ?? "",
                    confirmPassword: confirmPasswordField.text ?? ""
                )
                SessionManager.shared.saveSession(token: payload.token, user: payload.user, rememberedEmail: emailField.text)
                RootRouter.shared.routeAfterAuthentication(with: payload.user)
            } catch {
                errorLabel.text = error.localizedDescription
                errorLabel.isHidden = false
            }
        }
    }

    private func validateForm() -> String? {
        let trimmedName = (fullNameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = (usernameField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = (emailField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            return L10n.tr("auth.register.invalidName")
        }
        guard isValidUsername(trimmedUsername) else {
            return L10n.tr("auth.register.invalidUsername")
        }
        guard isValidEmail(trimmedEmail) else {
            return L10n.tr("auth.register.invalidEmail")
        }
        return nil
    }

    private func isValidEmail(_ value: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: value)
    }

    private func isValidUsername(_ value: String) -> Bool {
        let pattern = "^[a-z0-9._-]{3,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: value)
    }
}
