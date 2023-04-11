//
//  ResultViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 24/06/2021.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftConfettiView
import SwiftySound
import SwiftEntryKit

final class ResultViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var resultImageView: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelResult: UILabel!
    @IBOutlet weak var labelReason: UILabel!
    @IBOutlet weak var buttonShare: UIButton!
    @IBOutlet weak var buttonBack: CustomBorderButton!
    @IBOutlet weak var buttonTakeNewTest: CustomBorderButton!
    @IBOutlet weak var buttonTryAgain: CustomBorderButton!
    
    private var confettiView: SwiftConfettiView!
    
    // MARK: - Properties
    
    var viewModel: ResultViewModel!
    var disposeBag = DisposeBag()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupConfettiView()
        bindViewModel()
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    private func setupConfettiView() {
        confettiView = SwiftConfettiView(frame: self.view.bounds)
        confettiView.isUserInteractionEnabled = false
        confettiView.type = .confetti
        confettiView.intensity = 0.75
        confettiView.colors = [.red, .green, .blue]
        view.addSubview(confettiView)
        view.bringSubviewToFront(confettiView)
    }
    
    func bindViewModel() {
        let input = ResultViewModel.Input(firstLoadTrigger: rxViewWillAppear,
                                          buttonShareTrigger: buttonShare.rxButtonTapped,
                                          buttonTryAgainTrigger: buttonTryAgain.rxButtonTapped,
                                          buttonTakeNewTestTrigger: buttonTakeNewTest.rxButtonTapped,
                                          buttonBackToHomeTrigger: buttonBack.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .result
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] type in
                self?.resultImageView.image = type.image
                self?.labelResult.attributedText = type.score
                self?.labelTitle.text = type.title
                switch type {
                case .pass:
                    if let url = Bundle.main.url(forResource: "VICTORY", withExtension: "mp3") {
                        Sound.play(url: url)
                    }
                    self?.confettiView.startConfetti()
                    self?.buttonTakeNewTest.isHidden = false
                    self?.buttonTryAgain.isHidden = true
                case .fail:
                    if let url = Bundle.main.url(forResource: "FAIL", withExtension: "mp3") {
                        Sound.play(url: url)
                    }
                    self?.buttonTakeNewTest.isHidden = true
                    self?.buttonShare.isHidden = true
                    self?.labelReason.isHidden = false
                    
                    let correctPercentage = Double(type.result.correct ?? 1) / Double(type.result.total ?? 0) * 100
                    if correctPercentage <= 30 {
                        let alertVC = CustomAlertView()
                        let title = "Slow Down"
                        let buttonTitle = "OK"
                        alertVC.setupAlertView(title: title,
                                               description: "You’ve just scored under 30%. You will need to do the previous subject over again. This is to make sure you’re going through each subject with thought and care. Please think of this as a “speed bump” to slow you down.",
                                               type: .wrong,
                                               leftButtonTitle: buttonTitle,
                                               rightButtonTitle: nil,
                                               explainationLink: nil)
                        alertVC.onOKTapped = {
                            SwiftEntryKit.dismiss()
                        }
                        let attribute = EKAttributes.createCustomAlertAttributes(isDismissable: false)
                        SwiftEntryKit.display(entry: alertVC, using: attribute)
                    }
                }
            }),
         output
            .buttonShareInvoked
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] result in
                self?.showSharingVC()
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    func showSharingVC() {
        let screenshot = takeScreenshot()

        let title = "This is how I’m going to pass the next exam!"
        let url = URL(string: "https://apps.apple.com/us/app/bar-exam-drills/id1466447387")!
        let ac = UIActivityViewController(activityItems: [screenshot, title , url], applicationActivities: nil)
        present(ac, animated: true)
    }
    
    private func takeScreenshot() -> UIImage {
        let bounds = UIScreen.main.bounds
        UIGraphicsBeginImageContextWithOptions(bounds.size, true, 0.0)
        self.view.drawHierarchy(in: bounds, afterScreenUpdates: true)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return img!
    }
}
