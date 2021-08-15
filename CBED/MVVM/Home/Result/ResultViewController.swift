//
//  ResultViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 24/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

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
    
    // MARK: - Properties
    
    var viewModel: ResultViewModel!
    var disposeBag = DisposeBag()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
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
                    self?.buttonTakeNewTest.isHidden = false
                    self?.buttonTryAgain.isHidden = true
                case .fail:
                    self?.buttonTakeNewTest.isHidden = true
                    self?.buttonShare.isHidden = true
                    self?.labelReason.isHidden = false
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
        let title = "I love this app"
        let url = URL(string: "https://www.facebook.com/barexamdrills")!
        let ac = UIActivityViewController(activityItems: [title, screenshot, url], applicationActivities: nil)
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
