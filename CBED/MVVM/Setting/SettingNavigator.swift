//
//  SettingNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit

protocol SettingNavigatorType {
    func presentRestorePurchaseSuccessAlert()
}

struct SettingNavigator: SettingNavigatorType {
    unowned let navigationController: UINavigationController
    
    func presentRestorePurchaseSuccessAlert() {
        let alert = UIAlertHelper.showAlertController(title: "Restore Purchase Successful",
                                          message: "Successful restore your previous purchase",
                                          cancel: "OK",
                                          others: nil,
                                          handleAction: nil)
        
        navigationController.presentingViewController?.present(alert, animated: true)
    }
}
