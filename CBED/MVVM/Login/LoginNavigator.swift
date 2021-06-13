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
    func pushToLevelVC() {
        print("go to level VC")
    }
}
