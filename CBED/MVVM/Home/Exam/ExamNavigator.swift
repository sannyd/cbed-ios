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
    
    /// V261125.1 — the name of the exam explanation overlay entry.
    ///
    /// Naming the entry lets us dismiss *this specific* overlay instead of
    /// "whatever happens to be on screen", and lets us ask SwiftEntryKit
    /// "is the explanation overlay still up?" without guessing.
    static let answerResultEntryName = "cbed.exam.answerResult"
    
    /// V261125.1 — how long to wait for SwiftEntryKit's dismissal
    /// animation before displaying the next overlay anyway.
    ///
    /// SwiftEntryKit's dismiss completion is NOT guaranteed to fire:
    /// `EKRootViewController.didFinishDisplaying` starts with
    /// `guard !isDisplaying else { return }`, and it returns early when
    /// `keepWindowActive` is true. If the completion never fires, a
    /// completion-chained `display` would never run and the student would
    /// get NO overlay at all — a silent regression worse than the bug we
    /// are fixing. This timeout bounds that risk.
    private static let dismissCompletionTimeout: TimeInterval = 1.0
    
    let publisher = PublishSubject<CustomAlertViewPublisher>()
    let resultViewPublisher = PublishSubject<ResultViewModelPublisher>()
    
    func presentAnswerResult(result: QuestionEvaluationResult,
                             level: LevelM,
                             explainationLink: String?,
                             shouldUseContinueButtonTitle: Bool) {
        // V261125.1 — dismiss the previous overlay COMPLETELY before
        // displaying the next one, and never display two at once.
        //
        // The old code was:
        //
        //     if SwiftEntryKit.isCurrentlyDisplaying() {
        //         SwiftEntryKit.dismiss(.all)
        //     }
        //     ...
        //     SwiftEntryKit.display(entry: alertVC, using: attribute)
        //
        // `dismiss` is asynchronous — SwiftEntryKit animates the entry out
        // (0.4s scale + 0.2s fade) and only then tears the window down.
        // Calling `display` on the very next line starts a NEW entry
        // against a window that is still animating the OLD one out.
        //
        // Two things go wrong in that race:
        //
        //  1. `EKRootViewController.configure` calls `removeLastEntry`,
        //     which pops the outgoing entry with the POP animation while
        //     the dismissal animation is still running. The two overlap.
        //
        //  2. The explanation overlay is non-dismissible
        //     (`isDismissable: false` -> `screenInteraction = .absorbTouches`,
        //     `entryInteraction = .absorbTouches`, `displayDuration =
        //     .infinity`) and it lives in its OWN `EKWindow` above the app.
        //     If it is left installed, it absorbs EVERY touch app-wide. The
        //     student taps, hears the ping, sees the radio turn blue, and
        //     nothing happens — on the MEE screen AND on the MBE screen
        //     they switch to, because the overlay is bound to the window
        //     rather than to the view controller. Only a force-quit clears
        //     it.
        //
        // The fix: chain the display onto the dismissal completion, and
        // give the completion a timeout so a completion that never fires
        // cannot strand the student with no overlay at all.
        //
        // NOTE: `ExamNavigator` is a struct, so there is no `self` to
        // capture weakly — and none is needed. The closure captures the
        // immutable `result`, `level`, `explainationLink` and
        // `shouldUseContinueButtonTitle` values, and `publisher` is a
        // reference type whose lifetime the navigator already owns.
        let displayNewOverlay = {
            let alertVC = CustomAlertView()
            alertVC.publisher = self.publisher
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
            var attribute = EKAttributes.createCustomAlertAttributes(isDismissable: false)
            // V261125.1 — name the entry so it can be dismissed by name.
            attribute.name = Self.answerResultEntryName
            SwiftEntryKit.display(entry: alertVC, using: attribute)
        }
        
        // Only one explanation overlay may exist at a time. If one is up,
        // dismiss THAT one and display the new one when the dismissal has
        // finished. If none is up, display immediately.
        guard SwiftEntryKit.isCurrentlyDisplaying() else {
            displayNewOverlay()
            return
        }
        
        var didDisplay = false
        let displayOnce = {
            guard !didDisplay else { return }
            didDisplay = true
            displayNewOverlay()
        }
        
        SwiftEntryKit.dismiss(.all) {
            displayOnce()
        }
        
        // Safety net: SwiftEntryKit's dismiss completion is not guaranteed
        // to fire (see `dismissCompletionTimeout`). If it has not run by
        // then, display anyway — a slightly-overlapping overlay is far
        // better than no overlay at all.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.dismissCompletionTimeout) {
            displayOnce()
        }
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
