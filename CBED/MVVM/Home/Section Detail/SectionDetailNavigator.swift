//
//  SectionDetailNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import UIKit

protocol SectionDetailNavigatorType {
    func pushToPreviewWebView(usefulLinkURL: String)
    func pushToExamVC(sectionDetail: SectionDetailM,
                      level: LevelM)
    func pushToOutline(sectionDetail: SectionDetailM)
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
    
    func pushToExamVC(sectionDetail: SectionDetailM,
                      level: LevelM) {
        let examVC: ExamViewController = StoryboardManager.getVCFromHomeSB()
        examVC.viewModel = .init(useCase: ExamUseCase(),
                                 navigator: ExamNavigator(navigationController: navigationController),
                                 sectionDetail: sectionDetail,
                                 level: level)
        navigationController.pushViewController(examVC, animated: true)
    }
    
    func pushToOutline(sectionDetail: SectionDetailM) {
        let outlineVC: OutlineViewController = StoryboardManager.getVCFromHomeSB()
        outlineVC.outlineText = sectionDetail.questions?.last?.content
        navigationController.pushViewController(outlineVC, animated: true)
    }
}
