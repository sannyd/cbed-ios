//
//  RegisterViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 10/07/2021.
//

import UIKit
import RxSwift
import RxCocoa

final class RegisterViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var emailTextfield: UITextField!
    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet weak var stateTextfield: UITextField!
    @IBOutlet weak var buttonRegister: CustomBorderButton!
    // MARK: - Properties
    
    var viewModel: RegisterViewModel!
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
        let input = RegisterViewModel.Input(profileImage: .just(nil),
                                            name: nameTextfield.rx.text.orEmpty.asObservable(),
                                            email: emailTextfield.rx.text.orEmpty.asObservable(),
                                            password: passwordTextfield.rx.text.orEmpty.asObservable(),
                                            state: stateTextfield.rx.text.orEmpty.asObservable(),
                                            buttonRegisterTrigger: buttonRegister.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .isButtonRegisterValid
            .asDriver(onErrorJustReturn: false)
            .drive(buttonRegister.rx.isEnabled)]
            .forEach { $0.disposed(by: disposeBag) }
    }
}
