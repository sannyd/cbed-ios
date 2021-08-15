//
//  ResultNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 24/06/2021.
//

import UIKit

protocol ResultNavigatorType {
    func popViewController()
    func backToSectionsVC()
}

struct ResultNavigator: ResultNavigatorType {
    unowned let navigationController: UINavigationController
    
    func popViewController() {
        navigationController.popViewController(animated: true)
    }
    
    func backToSectionsVC() {
        for vc in navigationController.viewControllers where vc is SectionsViewController {
            navigationController.popToViewController(vc, animated: true)
        }
    }
}
