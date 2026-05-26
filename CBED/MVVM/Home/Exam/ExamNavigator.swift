//
//  ExamNavigator.swift
//  CBED
//
//  Created by Jimmy Hoang on 17/06/2021.
//

import UIKit
import RxSwift
import SwiftEntryKit

enum QuestionAlertType {
    case correct(points: Int)
    case partial(points: Int)
    case wrong(points: Int)
    
    var color: UIColor {
        switch self {
        case .correct(_):
            return #colorLiteral(red: 0.1607843137, green: 0.3568627451, blue: 0.8784313725, alpha: 1)
        case .partial(_):
            return #colorLiteral(red: 0.9450980392, green: 0.5882352941, blue: 0.1960784314, alpha: 1)
        case .wrong(_):
            return #colorLiteral(red: 0.8784313725, green: 0.1607843137, blue: 0.2470588235, alpha: 1)
        }
    }

    var pointsAwarded: Int {
        switch self {
        case .correct(let points),
             .partial(let points),
             .wrong(let points):
            return points
        }
    }
}

struct QuestionEvaluationResult {
    let type: QuestionAlertType
    let description: String?
}

protocol ExamNavigatorType {
    var publisher: PublishSubject<CustomAlertViewPublisher> { get }
    var resultViewPublisher: PublishSubject<ResultViewModelPublisher> { get }
    
    func presentAnswerResult(result: QuestionEvaluationResult,
                             level: LevelM,
                             explainationLink: String?,
                             shouldUseContinueButtonTitle: Bool)
    func pushToResultVC(result: SaveResultResponseM)
    func pushToPreviewWebView(usefulLinkURL: String)
    func popViewController()
}

struct ExamNavigator: ExamNavigatorType {
    unowned let navigationController: UINavigationController
    
    let publisher = PublishSubject<CustomAlertViewPublisher>()
    let resultViewPublisher = PublishSubject<ResultViewModelPublisher>()
    
    func presentAnswerResult(result: QuestionEvaluationResult,
                             level: LevelM,
                             explainationLink: String?,
                             shouldUseContinueButtonTitle: Bool) {
        let alertVC = CustomAlertView()
        alertVC.publisher = publisher
        let title: String
        let buttonTitle: String
        let usesRetryProgression = [30, 33, 35].contains(level.id)
        
        switch result.type {
        case .correct(_):
            title = "Correct"
            buttonTitle = shouldUseContinueButtonTitle ? "Continue" : "OK"
        case .partial(_):
            title = "Partially Correct"
            buttonTitle = usesRetryProgression ? "Try Again" : "Continue"
        case .wrong(_):
            title = "Wrong"
            buttonTitle = [5, 40].contains(level.id) || usesRetryProgression ? "Try Again" : "Continue"
        }
        
        alertVC.setupAlertView(title: title,
                               description: result.description,
                               type: result.type,
                               leftButtonTitle: buttonTitle,
                               rightButtonTitle: nil,
                               explainationLink: explainationLink)
        let attribute = EKAttributes.createCustomAlertAttributes(isDismissable: false)
        SwiftEntryKit.display(entry: alertVC, using: attribute)
    }
    
    func pushToResultVC(result: SaveResultResponseM) {
        let resultVC: ResultViewController = StoryboardManager.getVCFromHomeSB()
        resultVC.viewModel = .init(useCase: ResultUseCase(),
                                   navigator: ResultNavigator(navigationController: navigationController),
                                   result: result)
        resultVC.viewModel.publisher = resultViewPublisher
        navigationController.pushViewController(resultVC, animated: true)
    }
    
    func popViewController() {
        navigationController.popViewController(animated: true)
    }
    
    func pushToPreviewWebView(usefulLinkURL: String) {
        let previewVC = StoryboardManager.instancePreviewWebViewVC()
        previewVC.viewModel = .init(useCase: PreviewWebViewUseCase(),
                                    navigator: PreviewWebViewNavigator(),
                                    usefulLinkURL: usefulLinkURL)
        navigationController.pushViewController(previewVC, animated: true)
    }
}
