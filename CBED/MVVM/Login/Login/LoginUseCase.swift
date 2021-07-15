//
//  LoginUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import Foundation
import RxSwift

protocol LoginUseCaseType {
    func register(request: RegisterRequestM) -> Single<RegisterResponseM>
    func signin(email: String,
                password: String) -> Single<SignInResponseM>
    func singleSignOn(type: SSOType,
                      accessToken: String) -> Single<SingleSignOnResponseM>
}

struct LoginUseCase: LoginUseCaseType,
                     AuthUseCase {
    
}
