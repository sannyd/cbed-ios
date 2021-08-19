//
//  SearchNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 7/2/21.
//

import UIKit

protocol SearchNavigatorType {
    func pushToSectionDetailVC(sectionDetail: SectionDetailM)
    func pushToPreviewWebView(usefulLinkURL: String)
    func showBlockSectionAlert()
}

struct SearchNavigator: SearchNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToSectionDetailVC(sectionDetail: SectionDetailM) {
        let sectionDetailVC = StoryboardManager.instanceSectionDetailVC()
        sectionDetailVC.viewModel = .init(useCase: SectionDetailUseCase(),
                                          navigator: SectionDetailNavigator(navigationController: navigationController),
                                          sectionDetail: sectionDetail)
        navigationController.pushViewController(sectionDetailVC, animated: true)
    }
    
    func pushToPreviewWebView(usefulLinkURL: String) {
        let previewVC = StoryboardManager.instancePreviewWebViewVC()
        previewVC.viewModel = .init(useCase: PreviewWebViewUseCase(),
                                    navigator: PreviewWebViewNavigator(),
                                    usefulLinkURL: usefulLinkURL)
        navigationController.pushViewController(previewVC, animated: true)
    }
    
    func showBlockSectionAlert() {
        let alertView = UIAlertHelper.showAlertController(title: "Opps",
                                                      message: "You have to pass previous section in order to access this section",
                                                      cancel: "OK",
                                                      others: nil,
                                                      handleAction: nil)
        navigationController.presentingViewController?.present(alertView, animated: true)
    }
}
