//
//  StoryboardManager.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import UIKit

struct StoryboardManager {
    static let LoginSB = UIStoryboard(name: "Login", bundle: nil)
    
    static func instanceLoginVC() -> LoginViewController {
        return LoginSB.instantiateViewController(withIdentifier: LoginViewController.getClassName()) as! LoginViewController
    }
}

extension NSObject {
    static func getClassName() -> String {
        return String(describing: Self.self)
    }
}
