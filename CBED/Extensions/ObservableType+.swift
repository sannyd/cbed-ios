//
//  ObservableType.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 11/24/19.
//  Copyright © 2019 Advesa. All rights reserved.
//

import RxSwift
import RxCocoa

extension ObservableType {
    func catchErrorJustComplete() -> Observable<Element> {
        return `catch` { _ in
            return Observable.empty()
        }
    }
    
    func asDriverOnErrorJustComplete() -> Driver<Element> {
        return asDriver { _ in
            return Driver.empty()
        }
    }
    
    func mapToVoid() -> Observable<Void> {
        return map { _ in }
    }
}
