//
//  TabBarViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit

enum Swizzler {
    
    static func swizzleSelector(classToSwizzle: AnyClass,
                                originalSelector: Selector,
                                swizzledSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(classToSwizzle, originalSelector),
              let swizzledMethod = class_getInstanceMethod(classToSwizzle, swizzledSelector) else {
            return
        }
        
        let didAddMethod = class_addMethod(classToSwizzle,
                                           originalSelector,
                                           method_getImplementation(swizzledMethod),
                                           method_getTypeEncoding(swizzledMethod))
        
        if (didAddMethod) {
            class_replaceMethod(classToSwizzle,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
        
    }
}

class TabBarViewController: UITabBarController {
    init() {
        if #available(iOS 18.0, *) {
            Swizzler.swizzleSelector(classToSwizzle: TabBarViewController.self,
                                     originalSelector: NSSelectorFromString("_updateVisualStyleForTraitCollection:"),
                                     swizzledSelector: #selector(swizzeled__updateVisualStyleForTraitCollection(traitCollection:)))
        }
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        if #available(iOS 18.0, *) {
            Swizzler.swizzleSelector(classToSwizzle: TabBarViewController.self,
                                     originalSelector: NSSelectorFromString("_updateVisualStyleForTraitCollection:"),
                                     swizzledSelector: #selector(swizzeled__updateVisualStyleForTraitCollection(traitCollection:)))
        }
        
        super.init(coder: coder)
    }
    
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
        let settingNav = UINavigationController(rootViewController: settingVC)
        settingVC.viewModel = .init(useCase: SettingUseCase(), navigator: SettingNavigator(navigationController: settingNav))
        
        viewControllers = [levelNav, scoreboardNav, settingNav]
        addChild(levelNav)
        addChild(scoreboardNav)
        addChild(settingNav)
        tabBar.isTranslucent = false
        
        let tabBarHomeItem = UITabBarItem(title: "Home", image: #imageLiteral(resourceName: "img_deselected_home").withRenderingMode(.alwaysOriginal), selectedImage: #imageLiteral(resourceName: "img_selected_home"))
        let tabBarScoreboardItem = UITabBarItem(title: "Scoreboard", image: #imageLiteral(resourceName: "img_deselected_scoreboard").withRenderingMode(.alwaysOriginal), selectedImage:#imageLiteral(resourceName: "img_selected_scoreboard"))
        let tabBarSettingItem = UITabBarItem(title: "Settings", image: #imageLiteral(resourceName: "img_deselected_setting").withRenderingMode(.alwaysOriginal), selectedImage: #imageLiteral(resourceName: "img_selected_setting"))
        
        levelNav.tabBarItem = tabBarHomeItem
        scoreboardNav.tabBarItem = tabBarScoreboardItem
        settingNav.tabBarItem = tabBarSettingItem
        
        
        if #available(iOS 15.0, *) {

            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.backgroundColor = Constants.BackgroundColor
            appearance.selectionIndicatorTintColor = Constants.PrimaryBlue
            
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = UITabBar.appearance().standardAppearance
        } else {
            UITabBar.appearance().tintColor = Constants.PrimaryBlue
            UITabBar.appearance().unselectedItemTintColor = Constants.ColorC4C4C4
            UITabBar.appearance().barTintColor = Constants.BackgroundColor
        }

      
        
        // V11.1.14.1: scene-aware keyWindow accessor.
        guard let window = UIApplication.sceneKeyWindow else {
            return
        }
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let topBottom = window.safeAreaInsets.bottom == 0 ? window.safeAreaInsets.bottom : window.safeAreaInsets.bottom / 2.5
            levelNav.tabBarItem.imageInsets = .init(top: UIDevice.current.userInterfaceIdiom == .pad ? 0 : topBottom,
                                                    left: 0,
                                                    bottom: UIDevice.current.userInterfaceIdiom == .pad ? -35 : -topBottom,
                                                    right: 0)
            levelNav.tabBarItem.titlePositionAdjustment = .init(horizontal: 0, vertical: topBottom)
            scoreboardNav.tabBarItem.imageInsets = .init(top: UIDevice.current.userInterfaceIdiom == .pad ? 0 : topBottom,
                                                         left: 0,
                                                         bottom: UIDevice.current.userInterfaceIdiom == .pad ? -35 : -topBottom,
                                                         right: 0)
            scoreboardNav.tabBarItem.titlePositionAdjustment = .init(horizontal: 0, vertical: topBottom)
            settingNav.tabBarItem.imageInsets = .init(top: UIDevice.current.userInterfaceIdiom == .pad ? 0 : topBottom,
                                                      left: 0,
                                                      bottom: UIDevice.current.userInterfaceIdiom == .pad ? -35 : -topBottom,
                                                      right: 0)
            settingNav.tabBarItem.titlePositionAdjustment = .init(horizontal: 0, vertical: topBottom)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        AppUpdateChecker.shared.checkForUpdateIfNeeded(presenter: self)
    }
    
    @available(iOS 18.0, *)
    @objc dynamic
    func swizzeled__updateVisualStyleForTraitCollection(traitCollection: UITraitCollection) {
        guard traitCollection.userInterfaceIdiom == .pad else {
            // call super
            self.swizzeled__updateVisualStyleForTraitCollection(traitCollection: traitCollection)
            return
        }
        
        let phoneIdiomTraitCollection = traitCollection.modifyingTraits { mutableTraits in
            mutableTraits.userInterfaceIdiom = .phone
        }
        
        // call super with modified trait collection
        
        self.swizzeled__updateVisualStyleForTraitCollection(traitCollection: phoneIdiomTraitCollection)
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
