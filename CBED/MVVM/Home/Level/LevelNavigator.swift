//
//  LevelNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit

protocol LevelNavigatorType {
    func pushToSectionsVC(level: LevelM)
    func pushToSearchVC()
    func pushToInAppPurchaseVC()
}

struct LevelNavigator: LevelNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToSectionsVC(level: LevelM) {
        let sectionsVC = StoryboardManager.instanceSectionsVC()
        sectionsVC.viewModel = .init(useCase: SectionsUseCase(),
                                     navigator: SectionsNavigator(navigationController: navigationController),
                                     level: level)
        navigationController.pushViewController(sectionsVC, animated: true)
    }
    
    func pushToSearchVC() {
        let searchVC: SearchViewController = StoryboardManager.getVCFromHomeSB()
        searchVC.viewModel = .init(useCase: SearchUseCase(),
                                   navigator: SearchNavigator(navigationController: navigationController),
                                   level: LevelM(id: 9, name: "Essay Drills & Videos", order: nil))
        navigationController.pushViewController(searchVC, animated: true)
    }
    
    func pushToInAppPurchaseVC() {
        let inappPurchaseVC: InAppPurchaseViewController = StoryboardManager.getVCFromHomeSB()
        inappPurchaseVC.viewModel = .init(useCase: InAppPurchaseUseCase(),
                                          navigator: InAppPurchaseNavigator(navigationController: navigationController))
        navigationController.pushViewController(inappPurchaseVC, animated: true)
    }
}
