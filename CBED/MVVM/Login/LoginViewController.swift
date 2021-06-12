//
//  ViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 06/06/2021.
//

import UIKit
import RxSwift

class LoginViewController: UIViewController {
    @IBOutlet weak var textfieldEmail: UITextField!
    @IBOutlet weak var textfieldPassword: UITextField!
    @IBOutlet weak var buttonLogin: CustomBorderButton!
    @IBOutlet weak var buttonFacebook: UIImageView!
    @IBOutlet weak var buttonGoogle: UIImageView!
    @IBOutlet weak var buttonInstagram: UIImageView!
    @IBOutlet weak var buttonSignUp: UIButton!
    @IBOutlet weak var buttonForgot: UIButton!
    
    var viewModel: LoginViewModel!
    var disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func bindViewModel() {
        let input = createInput()
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .buttonLoginValid
            .drive(buttonLogin.rx.isEnabled),
         output
            .loginSuccess
            .drive()]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func createInput() -> LoginViewModel.Input {
        return .init(email: textfieldEmail.rx.text.orEmpty.asObservable(),
                     password: textfieldPassword.rx.text.orEmpty.asObservable(),
                     buttonLoginTrigger: buttonLogin.rxButtonTapped,
                     buttonFacebookTrigger: buttonFacebook.rxGestureTapped,
                     buttonGoogleTrigger: buttonGoogle.rxGestureTapped,
                     buttonInstagramTrigger: buttonInstagram.rxGestureTapped)
    }
}
