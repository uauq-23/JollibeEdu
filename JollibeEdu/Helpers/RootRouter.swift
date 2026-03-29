//
//  RootRouter.swift
//  JollibeEdu
//
//  Created by Lê Nguyễn Quốc Toàn on 20/3/26.
//

import UIKit

final class RootRouter {
    static let shared = RootRouter()

    private weak var window: UIWindow?

    private init() {}

    func attach(window: UIWindow) {
        self.window = window
        AppTheme.applyWindowAppearance(to: window)
    }

    func configureInitialRoot() {
        guard SessionManager.shared.token != nil else {
            showGuest(animated: false)
            return
        }

        Task { @MainActor in
            do {
                let user = try await AuthService.shared.getMe()
                SessionManager.shared.updateCurrentUser(user)
                if user.role.lowercased() == "admin" {
                    showAdmin(animated: false)
                } else {
                    showStudent(animated: false)
                }
            } catch {
                SessionManager.shared.clearSession()
                showGuest(animated: false)
            }
        }
    }

    func routeAfterAuthentication(with user: User) {
        if user.role.lowercased() == "admin" {
            showAdmin(animated: true)
        } else {
            showStudent(animated: true)
        }
    }

    func showGuest(animated: Bool) {
        let root = embedInNavigation(identifier: "GuestHomeViewController")
        setRoot(root, animated: animated)
    }

    func showLogin(animated: Bool) {
        let root = embedInNavigation(identifier: "LoginViewController")
        setRoot(root, animated: animated)
    }

    func showStudent(animated: Bool) {
        let controller: StudentTabBarController = instantiate(identifier: "StudentTabBarController")
        setRoot(controller, animated: animated)
    }

    func showAdmin(animated: Bool) {
        let controller: AdminRootTabBarController = instantiate(identifier: "AdminRootTabBarController")
        setRoot(controller, animated: animated)
    }

    func instantiate<T: UIViewController>(identifier: String) -> T {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        guard let controller = storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
            fatalError("Unable to instantiate \(identifier)")
        }
        return controller
    }

    func embedInNavigation(identifier: String) -> UINavigationController {
        let controller: UIViewController = instantiate(identifier: identifier)
        let navigationController = UINavigationController(rootViewController: controller)
        navigationController.navigationBar.prefersLargeTitles = true
        return navigationController
    }

    private func setRoot(_ controller: UIViewController, animated: Bool) {
        guard let window else { return }
        AppTheme.applyWindowAppearance(to: window)
        window.rootViewController = controller
        window.makeKeyAndVisible()

        guard animated else { return }
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
    }

    func reloadCurrentRoot(animated: Bool) {
        configureInitialRoot()
        if animated, let window {
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: nil, completion: nil)
        }
    }

    func updateWindowAppearance(animated: Bool) {
        guard let window else { return }

        let applyChanges = {
            AppTheme.applyWindowAppearance(to: window)
            window.rootViewController?.view.setNeedsLayout()
            window.rootViewController?.view.layoutIfNeeded()
        }

        if animated {
            UIView.transition(with: window, duration: 0.25, options: .transitionCrossDissolve, animations: applyChanges, completion: nil)
        } else {
            applyChanges()
        }
    }
}
