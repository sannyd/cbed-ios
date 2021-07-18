//
//  ForgotPasswordViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 14/07/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension ForgotPasswordViewModel {
    struct Input {
        let email: Observable<String>
        let buttonSendTrigger: Observable<Void>
    }
    
    struct Output {
        let isButtonSendValid: Observable<Bool>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct ForgotPasswordViewModel: ViewModel {
    let useCase: ForgotPasswordUseCaseType
    let navigator: ForgotPasswordNavigatorType
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let isButtonSendValid = input
            .email
            .map { email in
                return email.regularExpression("^(?:[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+(?:\\.[\\p{L}0-9!#$%\\&'*+/=?\\^_`{|}~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[\\p{L}0-9](?:[a-z0-9-]*[\\p{L}0-9])?\\.)+[\\p{L}0-9](?:[\\p{L}0-9-]*[\\p{L}0-9])?|\\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[\\p{L}0-9-]*[\\p{L}0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])$")
            }
        
        input
            .buttonSendTrigger
            .withLatestFrom(input.email)
            .flatMapLatest(requestForgotPassword(email:))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.showForgotPasswordSuccessAlert)
            .disposed(by: disposeBag)
        
        return Output(isButtonSendValid: isButtonSendValid,
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    func requestForgotPassword(email: String) -> Observable<Any> {
        self.useCase
            .forgotPassword(email: email)
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
