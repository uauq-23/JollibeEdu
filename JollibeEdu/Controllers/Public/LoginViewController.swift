import UIKit

final class LoginViewController: BaseStackContainerViewController {
    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var heroCardView: UIView!
    @IBOutlet private weak var formCardView: UIView!
    @IBOutlet private weak var inlineErrorView: UIView!
    @IBOutlet private weak var inlineErrorLabel: UILabel!
    @IBOutlet private weak var emailField: UITextField!
    @IBOutlet private weak var passwordField: UITextField!
    @IBOutlet private weak var rememberSwitch: UISwitch!
    @IBOutlet private weak var loginButton: UIButton!
    @IBOutlet private weak var forgotButton: UIButton!
    @IBOutlet private weak var registerButton: UIButton!
    @IBOutlet private weak var footerLabel: UILabel!

    override func buildContent() {
        title = L10n.tr("auth.login.title")
        navigationItem.largeTitleDisplayMode = .never

        heroCardView.applyCardStyle(backgroundColor: AppTheme.brandOrange)
        formCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        inlineErrorView.backgroundColor = AppTheme.dangerRed.withAlphaComponent(0.1)
        inlineErrorView.layer.cornerRadius = 16
        inlineErrorView.isHidden = true
        inlineErrorLabel.font = UIFont.systemFont(ofSize: 14, weight: .semibold)
        inlineErrorLabel.textColor = AppTheme.dangerRed
        inlineErrorLabel.numberOfLines = 0

        emailField.applyAppStyle(placeholder: L10n.tr("auth.login.identifier.placeholder"))
        emailField.text = SessionManager.shared.rememberedEmail
        passwordField.applyAppStyle(placeholder: L10n.tr("auth.login.password.placeholder"), secure: true)

        loginButton.applyPrimaryStyle()
        loginButton.setTitle(L10n.tr("auth.login.button"), for: .normal)
        forgotButton.applySecondaryOutlineStyle()
        forgotButton.setTitle(L10n.tr("auth.login.forgot"), for: .normal)
        registerButton.applySecondaryOutlineStyle()
        registerButton.setTitle(L10n.tr("auth.login.register"), for: .normal)

        rememberSwitch.onTintColor = AppTheme.brandOrange
        rememberSwitch.isOn = SessionManager.shared.rememberedEmail != nil

        forgotButton.addAction(UIAction { [weak self] _ in
            self?.performSegue(withIdentifier: "LoginShowForgotPassword", sender: self)
        }, for: .touchUpInside)

        registerButton.addAction(UIAction { [weak self] _ in
            self?.performSegue(withIdentifier: "LoginShowRegister", sender: self)
        }, for: .touchUpInside)

        footerLabel.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        footerLabel.textColor = AppTheme.textSecondary
        footerLabel.numberOfLines = 0
        footerLabel.text = L10n.tr("auth.login.footer")
        loginButton.addAction(UIAction { [weak self] _ in
            self?.submitLogin()
        }, for: .touchUpInside)
    }

    private func submitLogin() {
        inlineErrorView.isHidden = true
        loginButton.isEnabled = false
        loginButton.setTitle(L10n.tr("auth.login.loading"), for: .normal)

        Task { @MainActor in
            defer {
                loginButton.isEnabled = true
                loginButton.setTitle(L10n.tr("auth.login.button"), for: .normal)
            }

            do {
                let payload = try await AuthService.shared.login(identifier: emailField.text ?? "", password: passwordField.text ?? "")
                let rememberedEmail = rememberSwitch.isOn ? emailField.text : nil
                SessionManager.shared.saveSession(token: payload.token, user: payload.user, rememberedEmail: rememberedEmail)
                if !rememberSwitch.isOn {
                    SessionManager.shared.storeRememberedEmail(nil)
                }
                RootRouter.shared.routeAfterAuthentication(with: payload.user)
            } catch {
                showInlineError(error.localizedDescription)
            }
        }
    }

    private func showInlineError(_ message: String) {
        inlineErrorLabel.text = message
        inlineErrorView.isHidden = false
    }
}
