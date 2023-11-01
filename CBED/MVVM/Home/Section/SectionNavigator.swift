//
//  SectionNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import UIKit

protocol SectionsNavigatorType {
    func pushToSectionDetailVC(sectionDetail: SectionDetailM,
                               imageURL: String?,
                               level: LevelM)
    func pushToPreviewWebView(usefulLinkURL: String)
    func showBlockSectionAlert(sectionID: Int)
}

struct SectionsNavigator: SectionsNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToSectionDetailVC(sectionDetail: SectionDetailM,
                               imageURL: String?,
                               level: LevelM) {
        let sectionDetailVC = StoryboardManager.instanceSectionDetailVC()
        sectionDetailVC.viewModel = .init(useCase: SectionDetailUseCase(),
                                          navigator: SectionDetailNavigator(navigationController: navigationController),
                                          sectionDetail: sectionDetail,
                                          imageURL: imageURL,
                                          level: level)
        navigationController.pushViewController(sectionDetailVC, animated: true)
    }
    
    func pushToPreviewWebView(usefulLinkURL: String) {
        let previewVC = StoryboardManager.instancePreviewWebViewVC()
        previewVC.viewModel = .init(useCase: PreviewWebViewUseCase(),
                                    navigator: PreviewWebViewNavigator(),
                                    usefulLinkURL: usefulLinkURL)
        navigationController.pushViewController(previewVC, animated: true)
    }
    
    func showBlockSectionAlert(sectionID: Int) {
        var message = "You need to have mastered the previous level to 90% before accessing this level"
        switch sectionID {
        case 5:
            message = "You need to have mastered the previous level to 90% before accessing this level"
        case 10, 9:
            message = "You have to have be on Level 4 MBEs to access this section"
        default:
            break
        }
        
        let alertView = UIAlertHelper.showAlertController(title: "Sorry",
                                                      message: message,
                                                      cancel: "OK",
                                                      others: nil,
                                                      handleAction: nil)
        navigationController.presentingViewController?.present(alertView, animated: true)
    }
}
