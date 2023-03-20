//
//  Google+Reactive.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 1/6/20.
//  Copyright © 2020 Advesa. All rights reserved.
//

import GoogleSignIn
import RxSwift
import RxCocoa

extension Reactive where Base: GIDSignIn {
    func login(from: UIViewController?) -> Observable<String> {
        return .create { [weak base] observer in
            base?.signOut()
            base?.configuration = GIDConfiguration(clientID: "660482726170-lbmu7vtnugfrm6tb03oetv44361v7tci.apps.googleusercontent.com")
            base?.signIn(withPresenting: from!, completion: { result, error in
                if let error = error {
                    observer.on(.error(error))
                    return
                }
                
                guard let token = result?.user.idToken?.tokenString else {
                    observer.on(.error(FacebookSDKError.tokenNotFound))
                    return
                }
                
                observer.on(.next(token))
                observer.on(.completed)
            })
            
            return Disposables.create()
        }
    }
}
