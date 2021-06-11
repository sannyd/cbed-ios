//
//  UIAlertHelper.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 11/11/19.
//  Copyright © 2019 Advesa. All rights reserved.
//
import UIKit

public typealias HandleAlertAction = (_ alertAction: UIAlertAction, _ index: Int) -> Void
class UIAlertHelper: NSObject {
    
    @discardableResult
    public static func showAlertController(title: String?, message: String?, cancel: String?, others: [String]?, handleAction: HandleAlertAction?) -> UIAlertController {
        
        let alertVC = UIAlertController.init(title: title, message: message, preferredStyle: .alert)
        let actionCancel = UIAlertAction.init(title: cancel, style: .cancel) { (action) in
            guard let handleAction = handleAction else {
                return
            }
            handleAction(action, 0)
        }
        alertVC.addAction(actionCancel)
        
        if others != nil {
            for (index, title) in others!.enumerated() {
                let action = UIAlertAction.init(title: title, style: .default, handler: { (action) in
                    
                    if handleAction == nil {
                        return
                    }
                    handleAction!(action, index + 1)
                })
                alertVC.addAction(action)
            }
        }
        
        if let topVC = UIApplication.topViewController() {
            if !(topVC is UIAlertController) {
                topVC.present(alertVC, animated: true, completion: nil)
            }
//            else {
//                self.dismiss(animated: false, completion: {
//                    topVC.present(alertVC, animated: true, completion: nil)
//                })
//            }
        }
        
        return alertVC
    }
    
    @discardableResult
    public static func showActionSheetController(title: String?, cancel: String?, others: [String]?, anchorView: UIView?, sourceRect: CGRect?, handleAction: HandleAlertAction?) -> UIAlertController {
        
        let alertVC = UIAlertController.init(title: title, message: nil, preferredStyle: .actionSheet)
        let actionCancel = UIAlertAction.init(title: cancel, style: .cancel) { (action) in
            guard let handleAction = handleAction else {
                return
            }
            handleAction(action, 0)
        }
        alertVC.addAction(actionCancel)
        
        if others != nil {
            for (index, title) in others!.enumerated() {
                let action = UIAlertAction.init(title: title, style: .default, handler: { (action) in
                    if handleAction == nil {
                        return
                    }
                    handleAction!(action, index + 1)
                })
                alertVC.addAction(action)
            }
        }
        if let topVC = UIApplication.topViewController() {
            if !(topVC is UIAlertController) {
                if anchorView != nil, UIDevice.current.userInterfaceIdiom == .pad {
                    alertVC.popoverPresentationController?.sourceView = anchorView
                    alertVC.popoverPresentationController?.sourceRect = sourceRect != nil ? sourceRect! :(anchorView?.bounds)!
                    alertVC.popoverPresentationController?.permittedArrowDirections = .any
                }
                topVC.present(alertVC, animated: true, completion: nil)
            } else {
                self.dismiss(animated: false, completion: {
                    if anchorView != nil, UIDevice.current.userInterfaceIdiom == .pad {
                        alertVC.popoverPresentationController?.sourceView = anchorView
                        alertVC.popoverPresentationController?.sourceRect = sourceRect != nil ? sourceRect! :(anchorView?.bounds)!
                        alertVC.popoverPresentationController?.permittedArrowDirections = .any
                    }
                    topVC.present(alertVC, animated: true, completion: nil)
                })
            }
        }
        
        return alertVC
    }
    
    public static func dismiss(animated: Bool, completion: (() -> Swift.Void)? = nil) {
        if let currentAlertVC = UIApplication.topViewController(),
            currentAlertVC is UIAlertController {
            currentAlertVC.dismiss(animated: animated, completion: {
                if completion != nil {
                    completion!()
                }
            })
        }
    }
}
