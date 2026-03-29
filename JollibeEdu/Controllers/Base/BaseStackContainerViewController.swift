import UIKit

final class AppearanceToggleBarView: UIView {
    private let sunImageView = UIImageView(image: UIImage(systemName: "sun.max.fill"))
    private let moonImageView = UIImageView(image: UIImage(systemName: "moon.fill"))
    private let toggleSwitch = UISwitch()

    var onToggleChanged: ((Bool) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: 90, height: 32)
    }

    func setOn(_ isOn: Bool, animated: Bool) {
        toggleSwitch.setOn(isOn, animated: animated)
        updateIconColors()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false

        sunImageView.translatesAutoresizingMaskIntoConstraints = false
        sunImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        sunImageView.contentMode = .scaleAspectFit
        sunImageView.accessibilityLabel = L10n.tr("profile.appearance.light")

        moonImageView.translatesAutoresizingMaskIntoConstraints = false
        moonImageView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 13, weight: .semibold)
        moonImageView.contentMode = .scaleAspectFit
        moonImageView.accessibilityLabel = L10n.tr("profile.appearance.dark")

        toggleSwitch.onTintColor = AppTheme.brandOrange
        toggleSwitch.thumbTintColor = .white
        toggleSwitch.transform = CGAffineTransform(scaleX: 0.72, y: 0.72)
        toggleSwitch.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.updateIconColors()
            self.onToggleChanged?(self.toggleSwitch.isOn)
        }, for: .valueChanged)

        let row = UIFactory.makeHorizontalStack(spacing: 4, alignment: .center)
        row.addArrangedSubview(sunImageView)
        row.addArrangedSubview(toggleSwitch)
        row.addArrangedSubview(moonImageView)
        addSubview(row)

        NSLayoutConstraint.activate([
            row.topAnchor.constraint(equalTo: topAnchor),
            row.leadingAnchor.constraint(equalTo: leadingAnchor),
            row.trailingAnchor.constraint(equalTo: trailingAnchor),
            row.bottomAnchor.constraint(equalTo: bottomAnchor),
            sunImageView.widthAnchor.constraint(equalToConstant: 16),
            moonImageView.widthAnchor.constraint(equalToConstant: 16),
            heightAnchor.constraint(equalToConstant: 32)
        ])

        updateIconColors()
    }

    private func updateIconColors() {
        sunImageView.tintColor = toggleSwitch.isOn ? AppTheme.textSecondary : AppTheme.brandOrange
        moonImageView.tintColor = toggleSwitch.isOn ? AppTheme.brandOrange : AppTheme.textSecondary
    }
}

class BaseStackContainerViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var contentStackView: UIStackView!

    let loadingStateView = LoadingStateView()
    let emptyStateView = EmptyStateView()
    var clearsInitialStoryboardContent: Bool { true }
    private lazy var appearanceToggleView: AppearanceToggleBarView = {
        let view = AppearanceToggleBarView()
        view.onToggleChanged = { [weak self] isDark in
            self?.handleAppearanceToggleChanged(isDark)
        }
        return view
    }()
    private lazy var appearanceToggleBarButtonItem: UIBarButtonItem = {
        UIBarButtonItem(customView: appearanceToggleView)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (self: Self, _) in
            self.syncAppearanceToggle(animated: false)
        }
        configureBaseAppearance()
        if clearsInitialStoryboardContent {
            clearContent()
        }
        buildContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationAppearanceToggleIfNeeded()
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

    private var shouldShowAppearanceToggle: Bool {
        SessionManager.shared.isLoggedIn && !SessionManager.shared.isAdmin
    }

    private func configureNavigationAppearanceToggleIfNeeded() {
        guard shouldShowAppearanceToggle else {
            removeAppearanceToggle()
            return
        }

        syncAppearanceToggle(animated: false)

        var items = navigationItem.rightBarButtonItems ?? []
        if items.isEmpty, let rightItem = navigationItem.rightBarButtonItem {
            items = [rightItem]
        }
        if !items.contains(where: { $0 === appearanceToggleBarButtonItem }) {
            items.append(appearanceToggleBarButtonItem)
        }
        navigationItem.rightBarButtonItems = items
    }

    private func removeAppearanceToggle() {
        if let items = navigationItem.rightBarButtonItems {
            let filteredItems = items.filter { $0 !== appearanceToggleBarButtonItem }
            navigationItem.rightBarButtonItems = filteredItems.isEmpty ? nil : filteredItems
        } else if navigationItem.rightBarButtonItem === appearanceToggleBarButtonItem {
            navigationItem.rightBarButtonItem = nil
        }
    }

    private func syncAppearanceToggle(animated: Bool) {
        guard shouldShowAppearanceToggle else { return }
        let activeTraits = view.window?.traitCollection ?? traitCollection
        let isDark = AppSettingsManager.shared.appearanceMode.isDarkActive(for: activeTraits)
        appearanceToggleView.setOn(isDark, animated: animated)
    }

    private func handleAppearanceToggleChanged(_ isDark: Bool) {
        let targetMode: AppAppearanceMode = isDark ? .dark : .light
        guard AppSettingsManager.shared.appearanceMode != targetMode else { return }
        AppSettingsManager.shared.appearanceMode = targetMode
        RootRouter.shared.updateWindowAppearance(animated: true)
        syncAppearanceToggle(animated: false)
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
