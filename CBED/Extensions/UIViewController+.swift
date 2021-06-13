//
//  UIViewController+.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit
import RxSwift

extension UIViewController {
    public func logDeinit() {
        print(String(describing: type(of: self)) + " deinit")
    }
}

// MARK: Rx
extension UIViewController {
    var rxViewWillAppear: Observable<Void> {
        return rx
            .sentMessage(#selector(UIViewController.viewWillAppear))
            .take(1)
            .mapToVoid()
    }
}
