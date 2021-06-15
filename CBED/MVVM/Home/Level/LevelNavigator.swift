//
//  LevelNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit

protocol LevelNavigatorType {
    func pushToSectionsVC(levelID: Int)
}

struct LevelNavigator: LevelNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToSectionsVC(levelID: Int) {
        let sectionsVC = StoryboardManager.instanceSectionsVC()
        sectionsVC.viewModel = .init(useCase: SectionsUseCase(),
                                     navigator: SectionsNavigator(navigationController: navigationController),
                                     levelID: levelID)
        navigationController.pushViewController(sectionsVC, animated: true)
    }
}
