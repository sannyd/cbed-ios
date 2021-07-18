//
//  ForgotPasswordUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 14/07/2021.
//

import RxSwift

protocol ForgotPasswordUseCaseType {
    func forgotPassword(email: String) -> Single<Any>
}

struct ForgotPasswordUseCase: ForgotPasswordUseCaseType,
                              AuthUseCase {
    
}
