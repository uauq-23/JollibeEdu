import UIKit

final class ProfileViewController: AuthenticatedStackViewController, UITableViewDataSource, UITableViewDelegate {
    override var clearsInitialStoryboardContent: Bool { false }

    private enum MenuItem: CaseIterable {
        case language
        case changePassword
        case logout

        var title: String {
            switch self {
            case .language:
                return "\(L10n.tr("profile.menu.language")) • \(AppSettingsManager.shared.language.displayName)"
            case .changePassword:
                return L10n.tr("profile.menu.changePassword")
            case .logout:
                return L10n.tr("profile.menu.logout")
            }
        }

        var icon: String {
            switch self {
            case .language:
                return "globe"
            case .changePassword:
                return "lock.shield.fill"
            case .logout:
                return "rectangle.portrait.and.arrow.right"
            }
        }
    }

    private var currentUser: User?
    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var avatarLabel: UILabel!
    @IBOutlet private weak var roleLabel: UILabel!
    @IBOutlet private weak var profileCardView: UIView!
    @IBOutlet private weak var fullNameField: UITextField!
    @IBOutlet private weak var emailField: UITextField!
    @IBOutlet private weak var editSwitch: UISwitch!
    @IBOutlet private weak var saveButton: UIButton!
    @IBOutlet private weak var menuCardView: UIView!
    @IBOutlet private weak var menuContainerView: UIView!
    @IBOutlet private weak var menuHeightConstraint: NSLayoutConstraint!

    private lazy var menuTableView: IntrinsicTableView = {
        let tableView = IntrinsicTableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 100
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(ProfileMenuTableViewCell.self, forCellReuseIdentifier: ProfileMenuTableViewCell.reuseIdentifier)
        return tableView
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        menuTableView.reloadData()
        updateMenuHeight()
    }

    override func buildContent() {
        title = L10n.tr("profile.title")
        navigationItem.largeTitleDisplayMode = .never

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        profileCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        menuCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        avatarLabel.translatesAutoresizingMaskIntoConstraints = false
        avatarLabel.font = UIFont.boldSystemFont(ofSize: 34)
        avatarLabel.textAlignment = .center
        avatarLabel.textColor = .white
        avatarLabel.backgroundColor = AppTheme.brandOrange
        avatarLabel.layer.cornerRadius = 44
        avatarLabel.clipsToBounds = true

        roleLabel.translatesAutoresizingMaskIntoConstraints = false
        roleLabel.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        roleLabel.textAlignment = .center
        roleLabel.textColor = AppTheme.brandOrangeDark
        roleLabel.backgroundColor = AppTheme.mutedOrange.withAlphaComponent(0.45)
        roleLabel.layer.cornerRadius = 12
        roleLabel.clipsToBounds = true

        fullNameField.applyAppStyle(placeholder: L10n.tr("profile.fullname.placeholder"))
        fullNameField.autocapitalizationType = .words
        emailField.applyAppStyle(placeholder: L10n.tr("profile.email.placeholder"), keyboard: .emailAddress)
        emailField.autocapitalizationType = .none
        saveButton.applyPrimaryStyle()
        saveButton.setTitle(L10n.tr("profile.save"), for: .normal)

        editSwitch.onTintColor = AppTheme.brandOrange
        embed(menuTableView, in: menuContainerView)

        Task {
            await loadProfile()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMenuHeight()
    }

    private func embed(_ view: UIView, in container: UIView) {
        guard view.superview !== container else { return }
        view.removeFromSuperview()
        container.subviews.forEach { $0.removeFromSuperview() }
        view.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(view)
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: container.topAnchor),
            view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
    }

    private func updateMenuHeight() {
        menuTableView.layoutIfNeeded()
        menuHeightConstraint.constant = max(140, menuTableView.contentSize.height)
    }

    private func loadProfile() async {
        do {
            let user = try await AuthService.shared.getMe()
            currentUser = user
            SessionManager.shared.updateCurrentUser(user)
            avatarLabel.text = user.initials
            roleLabel.text = "  @\(user.displayUsername) • \(L10n.roleName(for: user.role))  "
            fullNameField.text = user.full_name
            emailField.text = user.email
            updateEditingState()
            menuTableView.reloadData()
            updateMenuHeight()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    private func updateEditingState() {
        let isEditing = editSwitch.isOn
        fullNameField.isEnabled = isEditing
        emailField.isEnabled = isEditing
        saveButton.isHidden = !isEditing
        fullNameField.alpha = isEditing ? 1 : 0.7
        emailField.alpha = isEditing ? 1 : 0.7
    }

    private func saveProfile() {
        saveButton.isEnabled = false
        saveButton.setTitle(L10n.tr("profile.saving"), for: .normal)
        Task { @MainActor in
            defer {
                saveButton.isEnabled = true
                saveButton.setTitle(L10n.tr("profile.save"), for: .normal)
            }

            do {
                let updated = try await UserService.shared.updateProfile(data: [
                    "full_name": fullNameField.text ?? "",
                    "email": emailField.text ?? ""
                ])
                currentUser = updated
                avatarLabel.text = updated.initials
                showSuccess(message: L10n.tr("profile.updated"))
            } catch {
                showError(message: error.localizedDescription)
            }
        }
    }

    @IBAction private func editSwitchChanged(_ sender: UISwitch) {
        updateEditingState()
    }

    @IBAction private func saveButtonTapped(_ sender: UIButton) {
        saveProfile()
    }

    private func handleMenuItem(_ item: MenuItem) {
        switch item {
        case .language:
            presentLanguagePicker()
        case .changePassword:
            performSegue(withIdentifier: "ProfileShowChangePassword", sender: self)
        case .logout:
            showConfirm(title: L10n.tr("profile.logout.title"), message: L10n.tr("profile.logout.message"), confirmTitle: L10n.tr("profile.logout.confirm")) {
                SessionManager.shared.clearSession()
                RootRouter.shared.showLogin(animated: true)
            }
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        MenuItem.allCases.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ProfileMenuTableViewCell.reuseIdentifier, for: indexPath) as? ProfileMenuTableViewCell else {
            return UITableViewCell()
        }
        let item = MenuItem.allCases[indexPath.row]
        let tint: UIColor = item == .logout ? AppTheme.dangerRed : AppTheme.brandOrange
        cell.configure(icon: item.icon, title: item.title, tint: tint)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        handleMenuItem(MenuItem.allCases[indexPath.row])
    }
}
