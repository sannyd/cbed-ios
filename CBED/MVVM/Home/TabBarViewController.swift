//
//  TabBarViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit

class TabBarViewController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBar.shadowImage = UIImage()
        tabBar.backgroundImage = UIImage()
        
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        tabBar.layer.shadowRadius = 6
        tabBar.layer.shadowColor = UIColor.black.cgColor
        tabBar.layer.shadowOpacity = 0.08
        
        let levelVC: LevelViewController = StoryboardManager.instanceLevelVC()
        let levelNav = UINavigationController(rootViewController: levelVC)
        levelVC.viewModel = .init(useCase: LevelUseCase(), navigator: LevelNavigator(navigationController: levelNav))
        
        let scoreboardVC: ScoreboardViewController = StoryboardManager.instanceScoreboardVC()
        scoreboardVC.viewModel = .init(useCase: ScoreboardUseCase(), navigator: ScoreboardNavigator())
        let scoreboardNav = UINavigationController(rootViewController: scoreboardVC)
        
        let settingVC: SettingViewController = StoryboardManager.instanceSettingVC()
        settingVC.viewModel = .init(useCase: SettingUseCase(), navigator: SettingNavigator())
        let settingNav = UINavigationController(rootViewController: settingVC)
        
        viewControllers = [levelNav, scoreboardNav, settingNav]
        addChild(levelNav)
        addChild(scoreboardNav)
        addChild(settingNav)
        tabBar.isTranslucent = false
        
        let tabBarHomeItem = UITabBarItem(title: "Home", image: #imageLiteral(resourceName: "img_deselected_home").withRenderingMode(.alwaysOriginal), selectedImage: #imageLiteral(resourceName: "img_selected_home"))
        let tabBarScoreboardItem = UITabBarItem(title: "Scoreboard", image: #imageLiteral(resourceName: "img_deselected_scoreboard").withRenderingMode(.alwaysOriginal), selectedImage:#imageLiteral(resourceName: "img_selected_scoreboard"))
        let tabBarSettingItem = UITabBarItem(title: "Setting", image: #imageLiteral(resourceName: "img_deselected_setting").withRenderingMode(.alwaysOriginal), selectedImage: #imageLiteral(resourceName: "img_selected_setting"))
        
        levelNav.tabBarItem = tabBarHomeItem
        scoreboardNav.tabBarItem = tabBarScoreboardItem
        settingNav.tabBarItem = tabBarSettingItem
        
        UITabBar.appearance().tintColor = Constants.PrimaryBlue
        UITabBar.appearance().unselectedItemTintColor = Constants.ColorC4C4C4
        UITabBar.appearance().barTintColor = Constants.BackgroundColor
        
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        
        if #available(iOS 11.0, *) {
            let topBottom = window.safeAreaInsets.bottom == 0 ? window.safeAreaInsets.bottom : window.safeAreaInsets.bottom / 2.5
            levelNav.tabBarItem.imageInsets = .init(top: UIDevice.current.userInterfaceIdiom == .pad ? 0 : topBottom, left: 0, bottom: -topBottom, right: 0)
            levelNav.tabBarItem.titlePositionAdjustment = .init(horizontal: 0, vertical: topBottom)
            scoreboardNav.tabBarItem.imageInsets = .init(top: UIDevice.current.userInterfaceIdiom == .pad ? 0 : topBottom, left: 0, bottom: -topBottom, right: 0)
            scoreboardNav.tabBarItem.titlePositionAdjustment = .init(horizontal: 0, vertical: topBottom)
            settingNav.tabBarItem.imageInsets = .init(top: UIDevice.current.userInterfaceIdiom == .pad ? 0 : topBottom, left: 0, bottom: -topBottom, right: 0)
            settingNav.tabBarItem.titlePositionAdjustment = .init(horizontal: 0, vertical: topBottom)
        } else {
//            levelNav.tabBarItem.imageInsets = .init(top: 0, left: -30, bottom: 0, right: 30)
//            scoreboardNav.tabBarItem.imageInsets = .init(top: 0, left: 30, bottom: 0, right: -30)
        }
//        if #available(iOS 13.0, *) {
//            let appearance = self.tabBar.standardAppearance
//            appearance.shadowImage = nil
//            appearance.shadowColor = nil
//            self.tabBar.standardAppearance = appearance
//        } else {
//            self.tabBar.shadowImage = UIImage()
//            self.tabBar.backgroundImage = UIImage()
//        }
    }
}

class CustomHeightTabBar : UITabBar {
    let height: CGFloat = 89
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        var sizeThatFits = super.sizeThatFits(size)
        if height > 0.0 {
            sizeThatFits.height = height
        }
        return sizeThatFits
    }
}
