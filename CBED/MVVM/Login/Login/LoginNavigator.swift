//
//  LoginNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import UIKit

protocol LoginNavigatorType {
    func pushToLevelVC()
    func pushToRegisterVC()
    func pushToForgotPasswordVC()
}

struct LoginNavigator: LoginNavigatorType {
    // V11.1.14.1: was `unowned let window: UIWindow`. Under the
    // scene-based lifecycle the window is owned by SceneDelegate
    // and AppDelegate.window is a strong mirror set in
    // SceneDelegate.scene(_:willConnectTo:options:). The mirror
    // keeps the window alive for the lifetime of the AppDelegate
    // (which is the lifetime of the app), so `unowned` is safe
    // here. The methods below refresh from the scene when the
    // captured ref might be stale (foreground/background cycle).
    unowned let window: UIWindow
    unowned let navigationController: UINavigationController

    func pushToLevelVC() {
        // V11.1.14.1: defensive — if the captured window happens
        // to be off-screen (multi-window future), fall back to the
        // currently-active key window.
        let activeWindow: UIWindow = window.isKeyWindow ? window
            : (UIApplication.sceneKeyWindow ?? window)
        let tabbarVC = StoryboardManager.instanceTabBarVC()
        activeWindow.rootViewController = tabbarVC
        activeWindow.makeKeyAndVisible()
    }
    
    func pushToRegisterVC() {
        let registerVC: RegisterViewController = StoryboardManager.getVCFromLoginSB()
        registerVC.viewModel = .init(useCase: RegisterUseCase(), navigator: RegisterNavigator(navigationController: navigationController))
        
        navigationController.pushViewController(registerVC, animated: true)
    }
    
    func pushToForgotPasswordVC() {
        let forgotPasswordVC: ForgotPasswordViewController = StoryboardManager.getVCFromLoginSB()
        forgotPasswordVC.viewModel = .init(useCase: ForgotPasswordUseCase(),
                                           navigator: ForgotPasswordNavigator(navigationController: navigationController))
        
        navigationController.pushViewController(forgotPasswordVC, animated: true)
    }
}
