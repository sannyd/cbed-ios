//
//  SectionNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import UIKit

protocol SectionsNavigatorType {
    func pushToSectionDetailVC(sectionInfo: SectionInfo)
}

struct SectionsNavigator: SectionsNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToSectionDetailVC(sectionInfo: SectionInfo) {
        let sectionDetailVC = StoryboardManager.instanceSectionDetailVC()
        sectionDetailVC.viewModel = .init(useCase: SectionDetailUseCase(),
                                          navigator: SectionDetailNavigator(navigationController: navigationController),
                                          sectionInfo: sectionInfo)
        navigationController.pushViewController(sectionDetailVC, animated: true)
    }
}
