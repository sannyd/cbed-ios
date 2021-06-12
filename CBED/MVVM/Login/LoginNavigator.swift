//
//  LoginNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import UIKit

protocol LoginNavigatorType {
    func pushToLevelVC()
}

struct LoginNavigator: LoginNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToLevelVC() {
        
    }
}
