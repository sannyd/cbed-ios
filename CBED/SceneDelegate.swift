//
//  SceneDelegate.swift
//  CBED
//
//  Created for iOS 27 / iPadOS 27 compliance. Adds the
//  UIWindowSceneDelegate lifecycle the App Store reviewer
//  expects. The window / root view controller setup that
//  used to live in `AppDelegate.application(_:didFinishLaunchingWithOptions:)`
//  has been moved here.
//
//  Reference: Guideline 2.1(a) — Launch crash on iPadOS 27
//  due to missing `UIApplicationSceneManifest` config.
//

import UIKit

@available(iOS 13.0, *)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else {
            // If we somehow get a non-window scene, refuse to create a
            // window — that path always crashes anyway and a clear
            // log line is more useful than a trap.
            assertionFailure("SceneDelegate: expected a UIWindowScene, got \(type(of: scene))")
            return
        }

        let window = UIWindow(windowScene: windowScene)
        self.window = window

        // V11.1.14.1: in a scene-based lifecycle the canonical
        // window lives on SceneDelegate. Legacy AppDelegate
        // methods (logout, applyAppTheme, getCurrentVC) still
        // reach through `AppDelegate.window`, so mirror the
        // reference here. Once SceneDelegate owns a window,
        // AppDelegate.window always returns the same instance.
        AppDelegate.shared?.window = window

        // Apply the saved theme (light / dark / system) BEFORE the
        // root VC is shown so the user never sees a flash of the
        // wrong style. The same call used to live in
        // AppDelegate.applyAppTheme().
        AppDelegate.shared?.applyAppThemeToWindow(window)

        // Root VC: AppViewController wired through the home storyboard.
        let appVC: AppViewController = StoryboardManager.getVCFromHomeSB()
        appVC.viewModel = .init(useCase: AppUseCase(), navigator: AppNavigator())
        window.rootViewController = appVC
        window.makeKeyAndVisible()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        // V11.1.14.1: when the scene tears down, drop the
        // AppDelegate's mirror of the window. SceneDelegate is
        // about to dealloc the window; if we kept the AppDelegate
        // ref alive, the legacy logout path could try to swap
        // rootViewController on a freed window and crash.
        if AppDelegate.shared?.window === self.window {
            AppDelegate.shared?.window = nil
        }
        self.window = nil
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Route to the legacy applicationDidBecomeActive so the
        // FaceID prompt logic in AppDelegate keeps working without
        // duplication.
        AppDelegate.shared?.applicationDidBecomeActiveForScene()
    }
}
