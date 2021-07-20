//
//  ForgotPasswordViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 14/07/2021.
//

import UIKit
import RxSwift
import RxCocoa

final class ForgotPasswordViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var buttonSend: CustomBorderButton!
    @IBOutlet weak var buttonBack: UIButton!
    
    // MARK: - Properties
    
    var viewModel: ForgotPasswordViewModel!
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
        let input = ForgotPasswordViewModel.Input(email: emailTextfield.rx.text.orEmpty.asObservable(),
                                                  buttonSendTrigger: buttonSend.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .isButtonSendValid
            .asDriverOnErrorJustComplete()
            .drive(buttonSend.rx.isEnabled),
        output
            .isLoading
            .asDriverOnErrorJustComplete()
            .drive(LoadingIndicatorView.rx.isAnimating),
        output
            .error
            .asDriverOnErrorJustComplete()
            .drive(errorBinding),
        buttonBack
            .rxButtonTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
}
