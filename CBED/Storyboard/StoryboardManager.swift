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
    static let SettingSB = UIStoryboard(name: "Setting", bundle: nil)
    
    static func instanceLoginVC() -> LoginViewController {
        return LoginSB.instantiateViewController(withIdentifier: LoginViewController.getClassName()) as! LoginViewController
    }
    
    static func instanceLevelVC() -> LevelViewController {
        return HomeSB.instantiateViewController(withIdentifier: LevelViewController.getClassName()) as! LevelViewController
    }
    
    static func instanceSectionsVC() -> SectionsViewController {
        return HomeSB.instantiateViewController(withIdentifier: SectionsViewController.getClassName()) as! SectionsViewController
    }
    
    static func instanceSectionDetailVC() -> SectionDetailViewController {
        return HomeSB.instantiateViewController(withIdentifier: SectionDetailViewController.getClassName()) as! SectionDetailViewController
    }
    
    static func instanceScoreboardVC() -> ScoreboardViewController {
        return HomeSB.instantiateViewController(withIdentifier: ScoreboardViewController.getClassName()) as! ScoreboardViewController
    }
    
    static func instanceSettingVC() -> SettingViewController {
        return SettingSB.instantiateViewController(withIdentifier: SettingViewController.getClassName()) as! SettingViewController
    }
    
    static func instanceTabBarVC() -> TabBarViewController {
        return HomeSB.instantiateViewController(withIdentifier: TabBarViewController.getClassName()) as! TabBarViewController
    }
    
    static func instancePreviewWebViewVC() -> PreviewWebViewViewController {
        return HomeSB.instantiateViewController(withIdentifier: PreviewWebViewViewController.getClassName()) as! PreviewWebViewViewController
    }
    
    static func instanceExamVC() -> ExamViewController {
        return HomeSB.instantiateViewController(withIdentifier: ExamViewController.getClassName()) as! ExamViewController
    }
    
    static func getVCFromHomeSB<T: UIViewController>() -> T {
        return HomeSB.instantiateViewController(withIdentifier: T.getClassName()) as! T
    }
    
    static func getVCFromSettingSB<T: UIViewController>() -> T {
        return SettingSB.instantiateViewController(withIdentifier: T.getClassName()) as! T
    }
    
    static func getVCFromLoginSB<T: UIViewController>() -> T {
        return LoginSB.instantiateViewController(withIdentifier: T.getClassName()) as! T
    }
}

extension NSObject {
    static func getClassName() -> String {
        return String(describing: Self.self)
    }
}
