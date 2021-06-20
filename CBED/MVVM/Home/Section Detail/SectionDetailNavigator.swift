//
//  SectionDetailNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import UIKit

protocol SectionDetailNavigatorType {
    func pushToPreviewWebView(usefulLinkURL: String)
    func pushToExamVC(sectionDetail: SectionDetailM)
}

struct SectionDetailNavigator: SectionDetailNavigatorType {
    unowned let navigationController: UINavigationController
    
    func pushToPreviewWebView(usefulLinkURL: String) {
        let previewVC = StoryboardManager.instancePreviewWebViewVC()
        previewVC.viewModel = .init(useCase: PreviewWebViewUseCase(),
                                    navigator: PreviewWebViewNavigator(),
                                    usefulLinkURL: usefulLinkURL)
        navigationController.pushViewController(previewVC, animated: true)
    }
    
    func pushToExamVC(sectionDetail: SectionDetailM) {
        let examVC: ExamViewController = StoryboardManager.getVCFromHomeSB()
        examVC.viewModel = .init(useCase: ExamUseCase(),
                                 navigator: ExamNavigator(navigationController: navigationController),
                                 sectionDetail: sectionDetail)
        navigationController.pushViewController(examVC, animated: true)
    }
}
