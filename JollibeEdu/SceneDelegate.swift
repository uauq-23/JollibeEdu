//
//  SceneDelegate.swift
//  JollibeEdu
//
//  Created by Lê Nguyễn Quốc Toàn on 20/3/26.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        AppTheme.applyWindowAppearance(to: window)
        self.window = window
        RootRouter.shared.attach(window: window)

        window.rootViewController = BootstrapLoadingViewController()
        window.makeKeyAndVisible()

        Task { @MainActor in
            await FirebaseSyncManager.shared.bootstrapRemoteState(with: DemoDataStore.shared.exportStatePayload())
            RootRouter.shared.configureInitialRoot()
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
    }

    func sceneWillResignActive(_ scene: UIScene) {
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
    }
}
