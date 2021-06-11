//
//  LoginViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 6/11/21.
//

import RxSwift
import RxCocoa


// MARK: Input + Output
extension LoginViewModel {
    struct Input {
        let email: Observable<String>
        let password: Observable<String>
        let buttonLoginTrigger: Observable<Void>
        let buttonFacebookTrigger: Observable<Void>
        let buttonGoogleTrigger: Observable<Void>
        let buttonInstagramTrigger: Observable<Void>
    }
    
    struct Output {
        let buttonLoginValid: Driver<Bool>
        let loginSuccess: Driver<Bool>
    }
}

struct LoginViewModel: ViewModel {
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let emailValid = input
            .email
            .map { email in
                return email.regularExpression("^(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])$")
            }
        
        let passwordValid = input
            .password
            .map { password in
                return password.minLength(min: 6, message: "")
            }
        
        let buttonLoginValid = Observable.merge(emailValid,
                                                passwordValid)
        
        return Output(buttonLoginValid: buttonLoginValid.asDriver(onErrorJustReturn: false),
                      loginSuccess: .just(true))
    }
}

public protocol ViewModel {
    associatedtype Input
    associatedtype Output
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output
}
