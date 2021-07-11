//
//  RegisterUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 10/07/2021.
//

import RxSwift

protocol RegisterUseCaseType {
    func register(request: RegisterRequestM) -> Single<RegisterResponseM>
}

struct RegisterUseCase: RegisterUseCaseType,
                        AuthUseCase {
    
}
