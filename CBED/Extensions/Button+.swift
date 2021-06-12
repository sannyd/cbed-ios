//
//  Button+.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 5/20/21.
//

import UIKit
import RxSwift

// MARK: Rx
extension UIButton {
    var rxButtonTapped: Observable<Void> {
        return rx
            .tap
            .asObservable()
    }
}
