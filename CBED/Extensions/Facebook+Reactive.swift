//
//  Facebook+Reactive.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 1/6/20.
//  Copyright © 2020 Advesa. All rights reserved.
//

import Foundation
import RxSwift
import FBSDKCoreKit
import FBSDKLoginKit

enum FacebookSDKError: Error {
    case tokenNotFound
}

extension Reactive where Base: LoginManager {
    func login(from: UIViewController?) -> Observable<AccessToken> {
        return Observable.create { [weak base] observer in
            base?.logOut()
            base?.logIn(permissions: ["email"], from: from) { result, error in
                if let error = error {
                    observer.on(.error(error))
                    return
                }
                
                guard !(result?.isCancelled ?? true) else {
                    observer.on(.completed)
                    return
                }
                
                guard let token = result?.token else {
                    observer.on(.error(FacebookSDKError.tokenNotFound))
                    return
                }
                observer.on(.next(token))
                observer.on(.completed)
            }
            
            return Disposables.create()
        }
    }
}

extension Reactive where Base: GraphRequest {
    static func fetchMe() -> Observable<String?> {
        return Observable.create { observer in
            let request = GraphRequest(graphPath: "me", parameters: ["fields": "email"])
            let task = request.start { _, result, error in
                if let error = error {
                    observer.on(.error(error))
                    return
                }
                
                guard let result = result as? [AnyHashable: Any] else {
                    observer.on(.error(FacebookSDKError.tokenNotFound))
                    return
                }
                
                let email = result["email"] as? String
                
                observer.on(.next(email))
                observer.on(.completed)
            }
            
            return Disposables.create {
                task.cancel()
            }
        }
    }
}
