//
//  UIViewController+.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit
import RxSwift
import Alamofire

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

struct ServerError: Error, Decodable {
    let code: String?
    let detail: String
}

struct ForgotPasswordError: Codable, Error {
    let email: [String]
}


extension UIViewController {
    var errorBinding: Binder<Error> {
        return Binder(self, binding: { (vc, error) in
            if let serverError = error as? ServerError {
                vc.showPopup(withTitle: "Error",
                             message: serverError.detail)
            } else if let customError = error as? CustomError {
                vc.showPopup(withTitle: "Error",
                             message: customError.errorString)
            } else if let forgotPassError = error as? ForgotPasswordError {
                    vc.showPopup(withTitle: "Error",
                                 message: forgotPassError.email.first)
            } else {
                vc.showPopup(withTitle: "Error",
                             message: "Something went wrong! Please try again later.")
            }
        })
    }
    
    func showPopup(withTitle title: String,
                   message: String?,
                   cancelMessage: String = "Close",
                   completion: (() -> Void)? = nil) {
        UIAlertHelper.showAlertController(title: title, message: message, cancel: cancelMessage, others: nil) { (_, _) in
            completion?()
        }
    }
}
