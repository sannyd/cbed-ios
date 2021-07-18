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
    unowned let window: UIWindow
    unowned let navigationController: UINavigationController
    
    func pushToLevelVC() {
        let tabbarVC = StoryboardManager.instanceTabBarVC()
        window.rootViewController = tabbarVC
        window.makeKeyAndVisible()
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
