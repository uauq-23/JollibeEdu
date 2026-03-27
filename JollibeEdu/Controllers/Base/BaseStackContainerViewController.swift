import UIKit

class BaseStackContainerViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentStackView: UIStackView!

    let loadingStateView = LoadingStateView()
    let emptyStateView = EmptyStateView()
    var clearsInitialStoryboardContent: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureBaseAppearance()
        if clearsInitialStoryboardContent {
            clearContent()
        }
        buildContent()
    }

    func configureBaseAppearance() {
        view.backgroundColor = AppTheme.warmBackground
        scrollView?.backgroundColor = .clear
        contentView?.backgroundColor = .clear
        contentStackView?.spacing = 18
        contentStackView?.layoutMargins = UIEdgeInsets(top: 4, left: 0, bottom: 24, right: 0)
        contentStackView?.isLayoutMarginsRelativeArrangement = true
    }

    func buildContent() {}

    func clearContent() {
        contentStackView.arrangedSubviews.forEach { view in
            contentStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func setLoadingVisible(_ visible: Bool) {
        if visible {
            if !contentStackView.arrangedSubviews.contains(loadingStateView) {
                contentStackView.insertArrangedSubview(loadingStateView, at: 0)
            }
        } else if contentStackView.arrangedSubviews.contains(loadingStateView) {
            contentStackView.removeArrangedSubview(loadingStateView)
            loadingStateView.removeFromSuperview()
        }
    }

    func showEmpty(icon: String, title: String, subtitle: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        clearContent()
        emptyStateView.configure(icon: icon, title: title, subtitle: subtitle, actionTitle: actionTitle)
        emptyStateView.onActionTapped = action
        contentStackView.addArrangedSubview(emptyStateView)
    }
}

class AuthenticatedStackViewController: BaseStackContainerViewController {
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard SessionManager.shared.isLoggedIn else {
            RootRouter.shared.showLogin(animated: true)
            return
        }
    }
}

class AdminProtectedViewController: AuthenticatedStackViewController {
    private lazy var settingsBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(image: UIImage(systemName: "gearshape.fill"), style: .plain, target: self, action: #selector(handleAdminSettings))
    }()

    private lazy var logoutBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(title: L10n.tr("admin.logout.confirm"), style: .plain, target: self, action: #selector(handleAdminLogout))
    }()

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard SessionManager.shared.isAdmin else {
            RootRouter.shared.showGuest(animated: true)
            return
        }
        configureAdminNavigationItems()
    }

    private func configureAdminNavigationItems() {
        var items = navigationItem.rightBarButtonItems ?? []
        if items.isEmpty, let rightItem = navigationItem.rightBarButtonItem {
            items = [rightItem]
        }
        if !items.contains(where: { $0 === settingsBarButtonItem }) {
            items.append(settingsBarButtonItem)
        }
        if !items.contains(where: { $0 === logoutBarButtonItem }) {
            items.append(logoutBarButtonItem)
        }
        navigationItem.rightBarButtonItems = items
    }

    @objc private func handleAdminSettings() {
        presentAppSettingsSheet(includeLogout: false)
    }

    @objc private func handleAdminLogout() {
        showConfirm(
            title: L10n.tr("admin.logout.title"),
            message: L10n.tr("admin.logout.message"),
            confirmTitle: L10n.tr("admin.logout.confirm")
        ) {
            SessionManager.shared.clearSession()
            RootRouter.shared.showLogin(animated: true)
        }
    }
}
