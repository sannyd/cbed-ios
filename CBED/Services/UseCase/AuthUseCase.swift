//
//  AuthUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import Foundation
import RxSwift
import Alamofire

enum SSOType: String, Decodable {
    case facebook
    case google
    case instagram
}

protocol AuthUseCase {
    func register(request: RegisterRequestM,
                  imageData: Data?) -> Single<RegisterResponseM>
    func signin(email: String,
                password: String) -> Single<SignInResponseM>
    func singleSignOn(type: SSOType,
                      accessToken: String) -> Single<SingleSignOnResponseM>
    func refreshToken(refreshToken: String) -> Single<TokenRefreshResponseM>
    func forgotPassword(email: String) -> Single<Any>
    func deactivate() -> Single<Any>
}

extension AuthUseCase {
    func register(request: RegisterRequestM,
                  imageData: Data?) -> Single<RegisterResponseM> {
        guard let params = request.toParams() else {
            return .error(CustomError.CannotGetParams)
        }
        
        let multipartFormData = MultipartFormData()
        
        if let imageData = imageData {
            multipartFormData.append(imageData, withName: "avatar", fileName: "avatar.jpg", mimeType: "image/jpg")
        }
        
        for (key, value) in params {
            multipartFormData.append((value as! String).data(using: .utf8)!, withName: key)
        }
        
        return APIClient
            .shared
            .upload(multipartFormData: multipartFormData,
                    urlConvertible: AuthRouter.register)
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
    
    func refreshToken(refreshToken: String) -> Single<TokenRefreshResponseM> {
        return APIClient
            .shared
            .request(AuthRouter.refreshToken(params: ["refresh": refreshToken]))
    }
    
    func forgotPassword(email: String) -> Single<Any> {
        return APIClient
            .shared
            .request(AuthRouter.forgotPassword(params: ["email": email]))
            .map { _ in }
    }
    
    func deactivate() -> Single<Any> {
        return APIClient
            .shared
            .request(AuthRouter.deactivate)
            .map { _ in }
    }
}
