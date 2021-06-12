//
//  UIView+.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import UIKit
import RxSwift
import RxGesture

// MARK: Rx
extension UIView {
    var rxGestureTapped: Observable<Void> {
        return rx
            .tapGesture()
            .when(.recognized)
            .mapToVoid()
    }
}
