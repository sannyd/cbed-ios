//
//  StoryboardManager.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import UIKit

struct StoryboardManager {
    static let LoginSB = UIStoryboard(name: "Login", bundle: nil)
    static let HomeSB = UIStoryboard(name: "Home", bundle: nil)
    
    static func instanceLoginVC() -> LoginViewController {
        return LoginSB.instantiateViewController(withIdentifier: LoginViewController.getClassName()) as! LoginViewController
    }
    
    static func instanceLevelVC() -> LevelViewController {
        return HomeSB.instantiateViewController(withIdentifier: LevelViewController.getClassName()) as! LevelViewController
    }
    
    static func instanceSectionsVC() -> SectionsViewController {
        return HomeSB.instantiateViewController(withIdentifier: SectionsViewController.getClassName()) as! SectionsViewController
    }
    
    static func instanceScoreboardVC() -> ScoreboardViewController {
        return HomeSB.instantiateViewController(withIdentifier: ScoreboardViewController.getClassName()) as! ScoreboardViewController
    }
    
    static func instanceSettingVC() -> SettingViewController {
        return HomeSB.instantiateViewController(withIdentifier: SettingViewController.getClassName()) as! SettingViewController
    }
    
    static func instanceTabBarVC() -> TabBarViewController {
        return HomeSB.instantiateViewController(withIdentifier: TabBarViewController.getClassName()) as! TabBarViewController
    }
}

extension NSObject {
    static func getClassName() -> String {
        return String(describing: Self.self)
    }
}
