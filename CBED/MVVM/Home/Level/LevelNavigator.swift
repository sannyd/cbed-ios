//
//  LevelNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit

protocol LevelNavigatorType {
    func pushToSectionsVC(levelID: Int,
                          levelTitle: String)
}

struct LevelNavigator: LevelNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToSectionsVC(levelID: Int,
                          levelTitle: String) {
        let sectionsVC = StoryboardManager.instanceSectionsVC()
        sectionsVC.viewModel = .init(useCase: SectionsUseCase(),
                                     navigator: SectionsNavigator(navigationController: navigationController),
                                     levelID: levelID,
                                     levelTitle: levelTitle)
        navigationController.pushViewController(sectionsVC, animated: true)
    }
}
