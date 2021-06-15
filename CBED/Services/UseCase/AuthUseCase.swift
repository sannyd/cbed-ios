//
//  AuthUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import Foundation
import RxSwift

enum SSOType: String, Decodable {
    case facebook
    case google
    case instagram
}

protocol AuthUseCase {
    func register(email: String,
                  password: String) -> Single<RegisterResponseM>
    func signin(email: String,
                password: String) -> Single<SignInResponseM>
    func singleSignOn(type: SSOType,
                      accessToken: String) -> Single<SingleSignOnResponseM>
}

extension AuthUseCase {
    func register(email: String,
                  password: String) -> Single<RegisterResponseM> {
        return APIClient
            .shared
            .request(AuthRouter.register(params: ["email": email,
                                                  "password": password]))
    }
    
    func signin(email: String,
                password: String) -> Single<SignInResponseM> {
        return APIClient
            .shared
            .request(AuthRouter.signIn(params: ["email": email,
                                                "password": password]))
    }
    
    func singleSignOn(type: SSOType,
                      accessToken: String) -> Single<SingleSignOnResponseM> {
        return APIClient
            .shared
            .request(AuthRouter.singleSignOn(params: ["sso_type": type.rawValue,
                                                      "access_token": accessToken]))
    }
}
