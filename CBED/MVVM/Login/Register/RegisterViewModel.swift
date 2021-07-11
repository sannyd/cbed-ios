//
//  RegisterViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 10/07/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension RegisterViewModel {
    struct Input {
        let profileImage: Observable<Data?>
        let name: Observable<String>
        let email: Observable<String>
        let password: Observable<String>
        let state: Observable<String>
        let buttonRegisterTrigger: Observable<Void>
    }
    
    struct Output {
        let isButtonRegisterValid: Observable<Bool>
    }
}

struct RegisterViewModel: ViewModel {
    let useCase: RegisterUseCaseType
    let navigator: RegisterNavigatorType
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        
        let sharedData = Observable.combineLatest(input.profileImage,
                                                  input.name,
                                                  input.email,
                                                  input.password,
                                                  input.state)
        
        let isButtonRegisterValid = sharedData
            .map { profileImage, name, email, password, state in
                return profileImage != nil &&
                    !name.isEmpty &&
                    !email.isEmpty &&
                    !password.isEmpty &&
                    !state.isEmpty
            }
        
        input
            .buttonRegisterTrigger
            .withLatestFrom(sharedData)
            .map { profileImage, name, email, password, state in
                return RegisterRequestM(name: name, email: email, password: password, state: state)
            }
            .flatMapLatest(register(request:))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.showRegisterSuccessAlert)
            .disposed(by: disposeBag)
        
        return Output(isButtonRegisterValid: isButtonRegisterValid)
    }
    
    private func register(request: RegisterRequestM) -> Observable<RegisterResponseM> {
        self.useCase
            .register(request: request)
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
