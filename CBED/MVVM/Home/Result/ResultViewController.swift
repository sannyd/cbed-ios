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
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let input = ResultViewModel.Input(firstLoadTrigger: rxViewWillAppear)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .result
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] type in
                self?.resultImageView.image = type.image
                self?.labelResult.attributedText = type.score
                switch type {
                case .pass:
                    self?.buttonTakeNewTest.isHidden = true
                case .fail:
                    self?.buttonTakeNewTest.isHidden = true
                    self?.buttonShare.isHidden = true
                    self?.labelReason.isHidden = false
                }
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
}
