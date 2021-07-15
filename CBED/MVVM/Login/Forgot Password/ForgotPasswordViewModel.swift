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
        
        
        return Output(isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
}
