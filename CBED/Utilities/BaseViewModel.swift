//
//  BaseViewModel.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 11/12/19.
//  Copyright © 2019 Advesa. All rights reserved.
//

import RxSwift
import RxCocoa

class BaseViewModel: NSObject {
    let activityIndicator = ActivityIndicator()
    let errorTracker = ErrorTracker()
    
    var indicator: Observable<Bool> {
        return activityIndicator.asObservable()
    }
}
