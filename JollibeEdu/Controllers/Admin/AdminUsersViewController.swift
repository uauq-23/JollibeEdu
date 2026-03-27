import UIKit

final class AdminUsersViewController: AdminProtectedViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDataSource, UITableViewDelegate {
    private struct UserFormDraft {
        var fullName: String
        var username: String
        var email: String
        var password: String
        var role: String
    }

    private let allowedRoles = ["student", "instructor", "admin"]
    private var allUsers: [User] = []
    private var filteredUsers: [User] = []
    private var metrics: [AdminSummaryMetric] = []
    private var activePickerAdapters: [TextFieldPickerAdapter] = []

    override var clearsInitialStoryboardContent: Bool { false }

    @IBOutlet private weak var headerCardView: UIView!
    @IBOutlet private weak var summaryCardView: UIView!
    @IBOutlet private weak var summaryContainerView: UIView!
    @IBOutlet private weak var summaryHeightConstraint: NSLayoutConstraint!
    @IBOutlet private weak var searchField: UITextField!
    @IBOutlet private weak var roleControl: UISegmentedControl!
    @IBOutlet private weak var listCardView: UIView!
    @IBOutlet private weak var listContainerView: UIView!
    @IBOutlet private weak var listHeightConstraint: NSLayoutConstraint!

    private lazy var summaryCollectionView: IntrinsicCollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 14
        layout.minimumInteritemSpacing = 14
        let view = IntrinsicCollectionView(frame: .zero, collectionViewLayout: layout)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.isScrollEnabled = false
        view.dataSource = self
        view.delegate = self
        view.register(AdminSummaryCardCollectionViewCell.self, forCellWithReuseIdentifier: AdminSummaryCardCollectionViewCell.reuseIdentifier)
        return view
    }()

    private lazy var tableView: IntrinsicTableView = {
        let tableView = IntrinsicTableView(frame: .zero, style: .plain)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(AdminListTableViewCell.self, forCellReuseIdentifier: AdminListTableViewCell.reuseIdentifier)
        return tableView
    }()

    override func buildContent() {
        title = L10n.tr("admin.users.title")
        navigationItem.largeTitleDisplayMode = .never
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addUserTapped))

        headerCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        summaryCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)
        listCardView.applyCardStyle(backgroundColor: AppTheme.cardBackground)

        searchField.applyAppStyle(placeholder: L10n.tr("admin.users.search.placeholder"))
        searchField.addTarget(self, action: #selector(filterChanged), for: .editingChanged)

        roleControl.setTitle(L10n.tr("common.all"), forSegmentAt: 0)
        roleControl.setTitle(L10n.roleName(for: "student"), forSegmentAt: 1)
        roleControl.setTitle(L10n.roleName(for: "instructor"), forSegmentAt: 2)
        roleControl.setTitle(L10n.roleName(for: "admin"), forSegmentAt: 3)
        roleControl.selectedSegmentIndex = 0
        roleControl.addAction(UIAction { [weak self] _ in self?.applyFilters() }, for: .valueChanged)
        embed(summaryCollectionView, in: summaryContainerView)
        embed(tableView, in: listContainerView)

        Task {
            await loadUsers()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateEmbeddedHeights()
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

    private func updateEmbeddedHeights() {
        summaryCollectionView.layoutIfNeeded()
        tableView.layoutIfNeeded()
        summaryHeightConstraint.constant = max(300, summaryCollectionView.collectionViewLayout.collectionViewContentSize.height)
        listHeightConstraint.constant = max(220, tableView.contentSize.height)
    }

    private func loadUsers() async {
        do {
            allUsers = try await UserService.shared.getAll(page: 1, limit: 200)
            metrics = [
                AdminSummaryMetric(symbol: "person.3.fill", title: L10n.tr("admin.users.metric.total"), value: "\(allUsers.count)"),
                AdminSummaryMetric(symbol: "person.fill", title: L10n.tr("admin.users.metric.students"), value: "\(allUsers.filter { $0.role == "student" }.count)"),
                AdminSummaryMetric(symbol: "person.crop.square.filled.and.at.rectangle", title: L10n.tr("admin.users.metric.instructors"), value: "\(allUsers.filter { $0.role == "instructor" }.count)"),
                AdminSummaryMetric(symbol: "lock.shield.fill", title: L10n.tr("admin.users.metric.admins"), value: "\(allUsers.filter { $0.role == "admin" }.count)")
            ]
            summaryCollectionView.reloadData()
            applyFilters()
            updateEmbeddedHeights()
        } catch {
            showError(message: error.localizedDescription)
        }
    }

    @objc private func filterChanged() {
        applyFilters()
    }

    private func applyFilters() {
        let query = (searchField.text ?? "").lowercased()
        let selectedRole: String?
        switch roleControl.selectedSegmentIndex {
        case 1: selectedRole = "student"
        case 2: selectedRole = "instructor"
        case 3: selectedRole = "admin"
        default: selectedRole = nil
        }

        filteredUsers = allUsers.filter { user in
            let matchesRole = selectedRole == nil || user.role == selectedRole
            let matchesQuery = query.isEmpty || user.full_name.lowercased().contains(query) || user.email.lowercased().contains(query)
            return matchesRole && matchesQuery
        }
        tableView.reloadData()
        updateEmbeddedHeights()
    }

    @objc private func addUserTapped() {
        presentUserForm(user: nil)
    }

    private func presentUserForm(user: User?, draft: UserFormDraft? = nil) {
        activePickerAdapters.removeAll()
        var selectedRole = draft?.role ?? user?.role ?? "student"
        let alert = UIAlertController(title: user == nil ? L10n.tr("admin.users.form.add") : L10n.tr("admin.users.form.edit"), message: L10n.tr("admin.users.form.message"), preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = L10n.tr("admin.users.form.fullname")
            textField.text = draft?.fullName ?? user?.full_name
        }
        alert.addTextField { textField in
            textField.placeholder = L10n.tr("admin.users.form.username")
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.text = draft?.username ?? user?.username
        }
        alert.addTextField { textField in
            textField.placeholder = L10n.tr("admin.users.form.email")
            textField.keyboardType = .emailAddress
            textField.autocapitalizationType = .none
            textField.autocorrectionType = .no
            textField.text = draft?.email ?? user?.email
        }
        alert.addTextField { textField in
            textField.placeholder = L10n.tr("admin.users.form.password")
            textField.isSecureTextEntry = true
            textField.text = draft?.password ?? ""
        }
        alert.addTextField { textField in
            textField.placeholder = L10n.tr("admin.users.form.role")
            let adapter = TextFieldPickerAdapter(
                textField: textField,
                options: self.allowedRoles,
                selectedValue: selectedRole,
                displayText: { [weak self] in self?.roleDisplayName(for: $0) ?? $0.capitalized },
                onSelection: { value in
                    selectedRole = value
                }
            )
            self.activePickerAdapters.append(adapter)
        }

        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel) { [weak self] _ in
            self?.activePickerAdapters.removeAll()
        })
        alert.addAction(UIAlertAction(title: L10n.tr("common.save"), style: .default) { [weak self] _ in
            guard let self else { return }
            self.activePickerAdapters.removeAll()
            let formDraft = UserFormDraft(
                fullName: alert.textFields?[0].text ?? "",
                username: alert.textFields?[1].text ?? "",
                email: alert.textFields?[2].text ?? "",
                password: alert.textFields?[3].text ?? "",
                role: selectedRole
            )

            guard let errorMessage = self.validateUserForm(formDraft, editingUser: user) else {
                Task { @MainActor in
                    do {
                        if let user {
                            _ = try await UserService.shared.update(id: user.id, data: [
                                "full_name": formDraft.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                                "username": formDraft.username.trimmingCharacters(in: .whitespacesAndNewlines),
                                "email": formDraft.email.trimmingCharacters(in: .whitespacesAndNewlines),
                                "password": formDraft.password,
                                "role": formDraft.role
                            ])
                        } else {
                            _ = try await UserService.shared.create(
                                fullName: formDraft.fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                                username: formDraft.username.trimmingCharacters(in: .whitespacesAndNewlines),
                                email: formDraft.email.trimmingCharacters(in: .whitespacesAndNewlines),
                                password: formDraft.password.isEmpty ? "User@123" : formDraft.password,
                                role: formDraft.role
                            )
                        }
                        await self.loadUsers()
                    } catch {
                        self.showError(message: error.localizedDescription) { [weak self] in
                            self?.presentUserForm(user: user, draft: formDraft)
                        }
                    }
                }
                return
            }

            self.showError(message: errorMessage) { [weak self] in
                self?.presentUserForm(user: user, draft: formDraft)
            }
        })
        present(alert, animated: true)
    }

    private func validateUserForm(_ draft: UserFormDraft, editingUser: User?) -> String? {
        let trimmedName = draft.fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = draft.username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = draft.email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            return L10n.tr("admin.users.form.invalidName")
        }
        guard isValidUsername(trimmedUsername) else {
            return L10n.tr("admin.users.form.invalidUsername")
        }
        guard isValidEmail(trimmedEmail) else {
            return L10n.tr("admin.users.form.invalidEmail")
        }
        guard allowedRoles.contains(draft.role) else {
            return L10n.tr("admin.users.form.invalidRole")
        }
        let usernameTaken = allUsers.contains { existingUser in
            existingUser.id != editingUser?.id && (existingUser.username ?? "").lowercased() == trimmedUsername.lowercased()
        }
        guard !usernameTaken else {
            return L10n.tr("admin.users.form.duplicateUsername")
        }
        let emailTaken = allUsers.contains { existingUser in
            existingUser.id != editingUser?.id && existingUser.email.lowercased() == trimmedEmail.lowercased()
        }
        guard !emailTaken else {
            return L10n.tr("admin.users.form.duplicateEmail")
        }
        return nil
    }

    private func isValidUsername(_ username: String) -> Bool {
        let pattern = "^[a-z0-9._-]{3,20}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: username)
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", pattern).evaluate(with: email)
    }

    private func roleDisplayName(for role: String) -> String {
        L10n.roleName(for: role)
    }

    private func resetPassword(for user: User) {
        let alert = UIAlertController(title: L10n.tr("admin.users.reset.title"), message: L10n.tr("admin.users.reset.message", user.full_name), preferredStyle: .alert)
        alert.addTextField { $0.placeholder = L10n.tr("admin.users.reset.placeholder") }
        alert.addAction(UIAlertAction(title: L10n.tr("common.cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: L10n.tr("admin.users.reset.confirm"), style: .default) { [weak self] _ in
            let newPassword = alert.textFields?.first?.text ?? "User@123"
            Task { @MainActor in
                do {
                    try await UserService.shared.resetPassword(userId: user.id, newPassword: newPassword)
                    self?.showSuccess(message: L10n.tr("admin.users.reset.success", user.full_name))
                } catch {
                    self?.showError(message: error.localizedDescription)
                }
            }
        })
        present(alert, animated: true)
    }

    private func deleteUser(_ user: User) {
        guard user.role != "admin" else {
            showError(message: L10n.tr("admin.users.delete.blocked"))
            return
        }
        showConfirm(title: L10n.tr("admin.users.delete.title"), message: L10n.tr("admin.users.delete.message", user.full_name), confirmTitle: L10n.tr("admin.users.delete.confirm")) { [weak self] in
            Task { @MainActor in
                do {
                    try await UserService.shared.delete(id: user.id)
                    if let self {
                        await self.loadUsers()
                    }
                } catch {
                    self?.showError(message: error.localizedDescription)
                }
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        metrics.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AdminSummaryCardCollectionViewCell.reuseIdentifier, for: indexPath) as? AdminSummaryCardCollectionViewCell else {
            return UICollectionViewCell()
        }
        let metric = metrics[indexPath.item]
        cell.configure(symbol: metric.symbol, title: metric.title, value: metric.value)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = floor((collectionView.bounds.width - 14) / 2)
        return CGSize(width: width, height: 132)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        max(filteredUsers.count, 1)
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard filteredUsers.indices.contains(indexPath.row) else {
            let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
            cell.selectionStyle = .none
            cell.textLabel?.text = L10n.tr("admin.users.empty.title")
            cell.detailTextLabel?.text = L10n.tr("admin.users.empty.subtitle")
            return cell
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: AdminListTableViewCell.reuseIdentifier, for: indexPath) as? AdminListTableViewCell else {
            return UITableViewCell()
        }
        let user = filteredUsers[indexPath.row]
        let tertiaryTitle = user.role == "admin" ? nil : L10n.tr("admin.users.action.delete")
        cell.configure(
            title: user.full_name,
            subtitle: "@\(user.displayUsername) • \(user.email)",
            status: roleDisplayName(for: user.role),
            primaryTitle: L10n.tr("admin.users.action.edit"),
            secondaryTitle: L10n.tr("admin.users.action.reset"),
            tertiaryTitle: tertiaryTitle,
            statusStyleKey: user.role
        )
        cell.onPrimaryTapped = { [weak self] in self?.presentUserForm(user: user) }
        cell.onSecondaryTapped = { [weak self] in self?.resetPassword(for: user) }
        cell.onTertiaryTapped = { [weak self] in self?.deleteUser(user) }
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard filteredUsers.indices.contains(indexPath.row) else { return nil }
        let user = filteredUsers[indexPath.row]
        guard user.role != "admin" else { return nil }
        let action = UIContextualAction(style: .destructive, title: L10n.tr("admin.users.action.delete")) { [weak self] _, _, completion in
            self?.deleteUser(user)
            completion(true)
        }
        return UISwipeActionsConfiguration(actions: [action])
    }
}
