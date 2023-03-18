//
//  ViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 06/06/2021.
//

import UIKit
import RxSwift
import GoogleSignIn

class LoginViewController: UIViewController {
    @IBOutlet weak var textfieldEmail: UITextField!
    @IBOutlet weak var textfieldPassword: UITextField!
    @IBOutlet weak var buttonLogin: CustomBorderButton!
//    @IBOutlet weak var buttonFacebook: UIImageView!
    @IBOutlet weak var buttonGoogle: UIImageView!
    @IBOutlet weak var buttonSignUp: UIButton!
    @IBOutlet weak var buttonForgot: UIButton!
    
    var viewModel: LoginViewModel!
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    private func bindViewModel() {
        let input = createInput()
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .buttonLoginValid
            .drive(buttonLogin.rx.isEnabled),
        output
            .isLoading
            .drive(LoadingIndicatorView.rx.isAnimating),
        output
            .error
            .drive(errorBinding)]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func createInput() -> LoginViewModel.Input {
        return .init(email: textfieldEmail.rx.text.orEmpty.asObservable(),
                     password: textfieldPassword.rx.text.orEmpty.asObservable(),
                     buttonLoginTrigger: buttonLogin.rxButtonTapped.do(onNext: { self.view.endEditing(true) }),
                     buttonFacebookTrigger: .never(),
                     buttonGoogleTrigger: buttonGoogle.rxGestureTapped,
                     buttonForgotPasswordTrigger: buttonForgot.rxButtonTapped,
                     buttonRegisterTrigger: buttonSignUp.rxButtonTapped)
    }
}

// MARK: UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == textfieldEmail {
            textfieldPassword.becomeFirstResponder()
        }
        
        if textField == textfieldPassword {
            view.endEditing(true)
        }
        
        return true
    }
}

