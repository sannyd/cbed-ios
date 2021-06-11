//
//  UIWindow+Extensions.swift
//  CantecCourier
//
//  Created by Jimmy Hoang on 11/13/20.
//

import UIKit

extension UIWindow {
    var visibleViewController: UIViewController? {
        return UIWindow.getVisibleViewControllerFrom(self.rootViewController)
    }
    
    static func getVisibleViewControllerFrom(_ viewController: UIViewController?) -> UIViewController? {
        if let navi = viewController as? UINavigationController {
            return UIWindow.getVisibleViewControllerFrom(navi.visibleViewController)
        } else if let tabbar = viewController as? UITabBarController {
            return UIWindow.getVisibleViewControllerFrom(tabbar.selectedViewController)
        } else {
            if let prensentedView = viewController?.presentedViewController {
                return UIWindow.getVisibleViewControllerFrom(prensentedView)
            } else {
                return viewController
            }
        }
    }
}
