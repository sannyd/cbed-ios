//
//  ViewModelType.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 11/15/19.
//  Copyright © 2019 Advesa. All rights reserved.
//

import Foundation
import RxSwift

protocol ViewModelType {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input, disposeBag: DisposeBag) -> Output
}
