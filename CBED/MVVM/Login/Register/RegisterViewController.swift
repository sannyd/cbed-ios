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
        let profileImageTrigger = profileImageView
            .rxGestureTapped
            .flatMap { _ -> Observable<Int> in
                return self.showAlert(title: "", message: "Choose or take an image", style: .actionSheet, actions: [
                    .init(title: "Camera", style: .default),
                    .init(title: "Gallery", style: .default),
                    .init(title: "Cancel", style: .cancel)
                ])
            }
        
        let input = RegisterViewModel.Input(profileImageTrigger: profileImageTrigger,
                                            name: nameTextfield.rx.text.orEmpty.asObservable(),
                                            email: emailTextfield.rx.text.orEmpty.asObservable(),
                                            password: passwordTextfield.rx.text.orEmpty.asObservable(),
                                            state: stateTextfield.rx.text.orEmpty.asObservable(),
                                            buttonRegisterTrigger: buttonRegister.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .isButtonRegisterValid
            .asDriver(onErrorJustReturn: false)
            .drive(buttonRegister.rx.isEnabled),
        output
            .isLoading
            .asDriver(onErrorJustReturn: false)
            .drive(LoadingIndicatorView.rx.isAnimating),
        output
            .error
            .asDriverOnErrorJustComplete()
            .drive(errorBinding)]
            .forEach { $0.disposed(by: disposeBag) }
    }
}

struct AlertAction {
    var title: String
    var style: UIAlertAction.Style
    
    static func action(title: String, style: UIAlertAction.Style = .default) -> AlertAction {
        return AlertAction(title: title, style: style)
    }
}

extension UIViewController {
    
    func showAlert(title: String?, message: String?, style: UIAlertController.Style, actions: [AlertAction])
     -> Observable<Int>
    {
        return Observable.create { observer in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
            
            actions.enumerated().forEach { index, action in
                let action = UIAlertAction(title: action.title, style: action.style) { _ in
                    observer.onNext(index)
                    observer.onCompleted()
                }
                alertController.addAction(action)
            }
            
            self.present(alertController, animated: true, completion: nil)
            
            return Disposables.create { alertController.dismiss(animated: true, completion: nil) }
        }
    }
}
