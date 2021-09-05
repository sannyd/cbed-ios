//
//  SettingNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit

protocol SettingNavigatorType {
    func presentRestorePurchaseSuccessAlert()
    func presentUpdateProfileVC()
}

struct SettingNavigator: SettingNavigatorType {
    unowned let navigationController: UINavigationController
    
    func presentRestorePurchaseSuccessAlert() {
        let alert = UIAlertHelper.showAlertController(title: "Success",
                                          message: "Previous purchase restored.",
                                          cancel: "OK",
                                          others: nil,
                                          handleAction: nil)
        
        navigationController.presentingViewController?.present(alert, animated: true)
    }
    
    func presentUpdateProfileVC() {
        let updateProfileVC: UpdateProfileViewController = StoryboardManager.getVCFromSettingSB()
        updateProfileVC.viewModel = .init(useCase: UpdateProfileUseCase(), navigator: UpdateProfileNavigator(navigationController: navigationController))
        navigationController.pushViewController(updateProfileVC, animated: true)
    }
}
