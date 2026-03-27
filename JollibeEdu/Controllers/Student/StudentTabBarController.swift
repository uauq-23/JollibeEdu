import UIKit

final class StudentTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureTabs()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard SessionManager.shared.isLoggedIn else {
            RootRouter.shared.showLogin(animated: true)
            return
        }
        if SessionManager.shared.isAdmin {
            RootRouter.shared.showAdmin(animated: true)
        }
    }

    private func configureTabs() {
        view.backgroundColor = AppTheme.warmBackground
        guard viewControllers?.isEmpty ?? true else { return }

        let home = makeNavigationController(identifier: "GuestHomeViewController", title: L10n.tr("tab.home"), symbol: "house.fill")
        let courses = makeNavigationController(identifier: "CourseListViewController", title: L10n.tr("tab.courses"), symbol: "books.vertical.fill")
        let dashboard = makeNavigationController(identifier: "DashboardViewController", title: L10n.tr("tab.dashboard"), symbol: "chart.bar.fill")
        let myCourses = makeNavigationController(identifier: "MyCoursesViewController", title: L10n.tr("tab.myCourses"), symbol: "play.rectangle.fill")
        let profile = makeNavigationController(identifier: "ProfileViewController", title: L10n.tr("tab.profile"), symbol: "person.crop.circle.fill")
        viewControllers = [home, courses, dashboard, myCourses, profile]
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
