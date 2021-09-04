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
    case correct
    case wrong
    
    var color: UIColor {
        switch self {
        case .correct:
            return #colorLiteral(red: 0.1607843137, green: 0.3568627451, blue: 0.8784313725, alpha: 1)
        case .wrong:
            return #colorLiteral(red: 0.8784313725, green: 0.1607843137, blue: 0.2470588235, alpha: 1)
        }
    }
}

protocol ExamNavigatorType {
    var publisher: PublishSubject<CustomAlertViewPublisher> { get }
    var resultViewPublisher: PublishSubject<ResultViewModelPublisher> { get }
    
    func presentAnswerResult(answer: AnswerM, level: LevelM)
    func pushToResultVC(result: SaveResultResponseM)
    func popViewController()
}

struct ExamNavigator: ExamNavigatorType {
    unowned let navigationController: UINavigationController
    
    let publisher = PublishSubject<CustomAlertViewPublisher>()
    let resultViewPublisher = PublishSubject<ResultViewModelPublisher>()
    
    func presentAnswerResult(answer: AnswerM, level: LevelM) {
        let alertVC = CustomAlertView()
        alertVC.publisher = publisher
        let isCorrect = answer.isCorrect
        let title = isCorrect ? "Correct" : "Wrong"
        let labelFail = level.id == 5 ? "Try Again" : "Continue"
        let buttonTitle = isCorrect ? "OK" : labelFail
        let type: QuestionAlertType = isCorrect ? .correct : .wrong
        alertVC.setupAlertView(title: title,
                               description: answer.discussion,
                               type: type,
                               leftButtonTitle: buttonTitle,
                               rightButtonTitle: nil)
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
}
