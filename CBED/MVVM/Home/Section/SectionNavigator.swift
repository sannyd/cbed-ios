//
//  SectionNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import UIKit

protocol SectionsNavigatorType {
    func pushToSectionDetailVC(sectionID: Int)
}

struct SectionsNavigator: SectionsNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToSectionDetailVC(sectionID: Int) {
        let sectionDetailVC = StoryboardManager.instanceSectionDetailVC()
        sectionDetailVC.viewModel = .init(useCase: SectionDetailUseCase(),
                                          navigator: SectionDetailNavigator(navigationController: navigationController),
                                          sectionID: sectionID)
        navigationController.pushViewController(sectionDetailVC, animated: true)
    }
}
