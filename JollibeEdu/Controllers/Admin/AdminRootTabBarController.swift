import UIKit

final class AdminRootTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabs()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard SessionManager.shared.isAdmin else {
            RootRouter.shared.showGuest(animated: true)
            return
        }
    }

    private func configureTabs() {
        view.backgroundColor = AppTheme.warmBackground
        guard viewControllers?.isEmpty ?? true else { return }

        let users = makeNavigationController(identifier: "AdminUsersViewController", title: L10n.tr("tab.users"), symbol: "person.3.fill")
        let courses = makeNavigationController(identifier: "AdminCoursesViewController", title: L10n.tr("tab.courses"), symbol: "book.closed.fill")
        let categories = makeNavigationController(identifier: "AdminCategoriesViewController", title: L10n.tr("tab.categories"), symbol: "square.grid.2x2.fill")
        let reports = makeNavigationController(identifier: "AdminReportsViewController", title: L10n.tr("tab.reports"), symbol: "chart.xyaxis.line")
        viewControllers = [users, courses, categories, reports]
    }

    private func makeNavigationController(identifier: String, title: String, symbol: String) -> UINavigationController {
        let controller: UIViewController = RootRouter.shared.instantiate(identifier: identifier)
        controller.title = title
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.prefersLargeTitles = true
        navigationController.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: symbol), selectedImage: UIImage(systemName: symbol))
        return navigationController
    }
}
