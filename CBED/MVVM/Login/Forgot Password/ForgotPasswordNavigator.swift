//
//  ForgotPasswordNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 14/07/2021.
//

import UIKit

protocol ForgotPasswordNavigatorType {
    func showForgotPasswordSuccessAlert()
}

struct ForgotPasswordNavigator: ForgotPasswordNavigatorType {
    unowned let navigationController: UINavigationController
    
    func showForgotPasswordSuccessAlert() {
        UIAlertHelper.showAlertController(title: "Congratulation", message: "You have successfully create your account", cancel: "OK", others: nil) { _, index in
            navigationController.popViewController(animated: true)
        }
    }
}
