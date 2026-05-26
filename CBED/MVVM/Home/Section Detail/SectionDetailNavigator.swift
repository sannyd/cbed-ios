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
                      level: LevelM,
                      customTimeLimitMinutes: Int?)
    func pushToOutline(sectionDetail: SectionDetailM,
                       level: LevelM)
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
                      level: LevelM,
                      customTimeLimitMinutes: Int?) {
        let examVC: ExamViewController = StoryboardManager.getVCFromHomeSB()
        examVC.viewModel = .init(useCase: ExamUseCase(),
                                 navigator: ExamNavigator(navigationController: navigationController),
                                 sectionDetail: sectionDetail,
                                 level: level,
                                 customTimeLimitMinutes: customTimeLimitMinutes)
        navigationController.pushViewController(examVC, animated: true)
    }
    
    func pushToOutline(sectionDetail: SectionDetailM,
                       level: LevelM) {
        let outlineVC: OutlineViewController = StoryboardManager.getVCFromHomeSB()
        if level.id == 9 { // Essay
            outlineVC.navTitle = "Essay Outline"
        }
        
        if level.id == 7 { // MEE
            outlineVC.navTitle = "Essay Outline"
        }
        
        if level.id == 14 { //  GA Essay Drills
            outlineVC.navTitle = "Essay Outline"
        }
        
        if level.id == 8 { // Free
            outlineVC.navTitle = "Essay Outline"
        }
        
        if level.id == 13 { // FL Essay Drills
            outlineVC.navTitle = "Essay Outline"
        }

        if level.id == 31 { // IQS Drafting Sets
            outlineVC.navTitle = "Drafting Outline"
        }

        if level.id == 33 { // IQS Counseling Sets
            outlineVC.navTitle = "Counseling Outline"
        }
        
        if level.id == 10 { // M/PT
            outlineVC.navTitle = "M/PT Outline"
        }
        
        if level.id == 11 { // MPT
            outlineVC.navTitle = "MPT Outline"
        }

        if level.id == 34 { // SPT
            outlineVC.navTitle = "SPT Outline"
        }

        if level.id == 35 { // LRPT
            outlineVC.navTitle = "LRPT Outline"
        }
        
        
        outlineVC.outlineText = sectionDetail.questions?.last?.content
        navigationController.pushViewController(outlineVC, animated: true)
    }
}
