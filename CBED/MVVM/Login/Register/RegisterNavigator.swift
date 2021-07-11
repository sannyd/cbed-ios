//
//  RegisterNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 10/07/2021.
//

import UIKit

protocol RegisterNavigatorType {
    func showRegisterSuccessAlert()
}

struct RegisterNavigator: RegisterNavigatorType {
    unowned let navigationController: UINavigationController
    
    func showRegisterSuccessAlert() {
        UIAlertHelper.showAlertController(title: "Congratulation", message: "You have successfully create your account", cancel: "OK", others: nil) { _, index in
            navigationController.popViewController(animated: true)
        }
    }
}
