//
//  LoginUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import Foundation
import RxSwift

protocol LoginUseCaseType {
    func register(email: String,
                  password: String) -> Single<RegisterResponseM>
    func signin(email: String,
                password: String) -> Single<SignInResponseM>
}

struct LoginUseCase: LoginUseCaseType,
                     AuthUseCase {
    
}
