//
//  InAppPurchaseNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 07/07/2021.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftEntryKit

protocol InAppPurchaseNavigatorType {
    var alertViewPublisher: PublishSubject<InAppPurchaseAlertViewPublisher> { get }
    
    func showMonthAlertView(leftData: InAppPurchaseMonth,
                            rightData: InAppPurchaseMonth)
    func presentRestorePurchaseSuccessAlert()
}

struct InAppPurchaseNavigator: InAppPurchaseNavigatorType {
    unowned let navigationController: UINavigationController
    
    var alertViewPublisher = PublishSubject<InAppPurchaseAlertViewPublisher>()
    
    func showMonthAlertView(leftData: InAppPurchaseMonth,
                            rightData: InAppPurchaseMonth) {
        let alertVC = InAppPurchaseAlertView(viewModel: .init(leftData: BehaviorRelay<InAppPurchaseMonthM>(value: .init(isSelected: false, type: leftData)),
                                                              rightData: BehaviorRelay<InAppPurchaseMonthM>(value: .init(isSelected: false, type: rightData))))
        alertVC.publisher = alertViewPublisher
        
        let attribute = EKAttributes.createCustomAlertAttributes(isDismissable: true)
        SwiftEntryKit.display(entry: alertVC, using: attribute)
    }
    
    func presentRestorePurchaseSuccessAlert() {
        let alert = UIAlertHelper.showAlertController(title: "Success",
                                          message: "Previous purchase restored.",
                                          cancel: "OK",
                                          others: nil,
                                          handleAction: { _, _ in
                                            navigationController.popViewController(animated: true)
                                          })
        
        navigationController.presentingViewController?.present(alert, animated: true)
    }
}
