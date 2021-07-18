//
//  LoginViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 6/11/21.
//

import RxSwift
import RxCocoa
import FBSDKLoginKit
import GoogleSignIn

// MARK: Input + Output
extension LoginViewModel {
    struct Input {
        let email: Observable<String>
        let password: Observable<String>
        let buttonLoginTrigger: Observable<Void>
        let buttonFacebookTrigger: Observable<Void>
        let buttonGoogleTrigger: Observable<Void>
        let buttonForgotPasswordTrigger: Observable<Void>
        let buttonRegisterTrigger: Observable<Void>
    }
    
    struct Output {
        let buttonLoginValid: Driver<Bool>
        let isLoading: Driver<Bool>
        let error: Driver<Error>
    }
}

struct LoginViewModel: ViewModel {
    let useCase: LoginUseCase
    let navigator: LoginNavigatorType
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    let loginManager = LoginManager()
    
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
        
        let buttonLoginValid = Observable.combineLatest(emailValid,
                                                        passwordValid)
            .map { $0 && $1 }
        
        let loginData = Observable
            .combineLatest(input.email,
                           input.password)
        
        // Handle Email login
        let loginSuccess = input
            .buttonLoginTrigger
            .withLatestFrom(loginData)
            .flatMapLatest(handleNormalLogin(email:password:))
            .do(onNext: { response in
                Storage.accessToken = response.token.access
                Storage.refreshToken = response.token.refresh
                APIClient.shared.readInterceptor()
            })
            .mapToVoid()
        
        // Handle Facebook login
        let facebookLoginSuccess = input
            .buttonFacebookTrigger
            .flatMapLatest { showFacebookLogin }
            .flatMapLatest(handleSingleSignOn(type:accessToken:))
            .do(onNext: { response in
                Storage.accessToken = response.token.access
                Storage.refreshToken = response.token.refresh
                APIClient.shared.readInterceptor()
            })
            .mapToVoid()
        
        // Handle Google login
        let googleLoginSuccess = input
            .buttonGoogleTrigger
            .flatMapLatest { showGoogleLogin }
            .flatMapLatest(handleSingleSignOn(type:accessToken:))
            .delay(.seconds(1), scheduler: MainScheduler.instance)
            .do(onNext: { response in
                Storage.accessToken = response.token.access
                Storage.refreshToken = response.token.refresh
                APIClient.shared.readInterceptor()
            })
            .mapToVoid()
        
        Observable
            .merge(loginSuccess,
                   facebookLoginSuccess,
                   googleLoginSuccess)
            .flatMapLatest(fetchProfileInfo)
            .do(onNext: { profile in
                Storage.profileInfo = profile
            })
            .mapToVoid()
            .subscribe(onNext: navigator.pushToLevelVC)
            .disposed(by: disposeBag)
        
        // Handle sign up tapped
        input
            .buttonRegisterTrigger
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToRegisterVC)
            .disposed(by: disposeBag)
        
        // Handle forgot password tapped
        input
            .buttonForgotPasswordTrigger
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToForgotPasswordVC)
            .disposed(by: disposeBag)
        
        return Output(buttonLoginValid: buttonLoginValid.asDriver(onErrorJustReturn: false),
                      isLoading: activityIndicator.asDriver(),
                      error: errorTracker.asDriver())
    }
    
    private func handleNormalLogin(email: String,
                                   password: String) -> Observable<SignInResponseM> {
        return useCase
            .signin(email: email,
                    password: password)
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
    
    private var showFacebookLogin: Observable<(SSOType, String)> {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        return loginManager
            .rx
            .login(from: appDelegate.getCurrentViewController())
            .trackError(errorTracker)
            .catch { _ in
                return .never()
            }
            .map { (SSOType.facebook, $0.tokenString) }
    }
    
    private var showGoogleLogin: Observable<(SSOType, String)> {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        return GIDSignIn
            .sharedInstance
            .rx
            .login(from: appDelegate.getCurrentViewController())
            .trackError(self.errorTracker)
            .catch { _ in
                return .never()
            }
            .map { accessToken in (SSOType.google,
                                   accessToken) }
    }
    
    private func handleSingleSignOn(type: SSOType, accessToken: String) -> Observable<SingleSignOnResponseM> {
        return self.useCase
            .singleSignOn(type: type,
                          accessToken: accessToken)
            .trackActivity(self.activityIndicator)
            .trackError(self.errorTracker)
            .catch({ (error) -> Observable<SingleSignOnResponseM> in
                return .never()
            })
    }
    
    private func fetchProfileInfo() -> Observable<ProfileInfoM> {
        return self.useCase
            .getProfileInfo()
            .trackActivity(self.activityIndicator)
            .trackError(self.errorTracker)
            .catch({ (error) -> Observable<ProfileInfoM> in
                return .never()
            })
    }
}

public protocol ViewModel {
    associatedtype Input
    associatedtype Output
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output
}
