//
//  SectionNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import UIKit

protocol SectionsNavigatorType {
    func pushToSectionDetailVC(sectionDetail: SectionDetailM,
                               imageURL: String?)
    func pushToPreviewWebView(usefulLinkURL: String)
    func showBlockSectionAlert(sectionID: Int)
}

struct SectionsNavigator: SectionsNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToSectionDetailVC(sectionDetail: SectionDetailM,
                               imageURL: String?) {
        let sectionDetailVC = StoryboardManager.instanceSectionDetailVC()
        sectionDetailVC.viewModel = .init(useCase: SectionDetailUseCase(),
                                          navigator: SectionDetailNavigator(navigationController: navigationController),
                                          sectionDetail: sectionDetail,
                                          imageURL: imageURL)
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
        var message = "You have to pass previous section in order to access this section"
        switch sectionID {
        case 5:
            message = "You need to have passed the previous MBE Level to access this level"
        case 10, 9:
            message = "You have to have be on Level 4 MBEs to access this section"
        default:
            break
        }
        
        let alertView = UIAlertHelper.showAlertController(title: "Oops",
                                                      message: message,
                                                      cancel: "OK",
                                                      others: nil,
                                                      handleAction: nil)
        navigationController.presentingViewController?.present(alertView, animated: true)
    }
}
