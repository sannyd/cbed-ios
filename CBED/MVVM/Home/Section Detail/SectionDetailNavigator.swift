//
//  SectionDetailNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import UIKit

protocol SectionDetailNavigatorType {
    func pushToPreviewWebView(usefulLinkURL: String)
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
}
