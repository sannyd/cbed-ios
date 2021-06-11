//
//  UIApplication+Extensions.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 11/11/19.
//  Copyright © 2019 Advesa. All rights reserved.
//

import UIKit

extension UIApplication {
    public static func topViewController(controller: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        
        if let navigationVC = controller as? UINavigationController {
            return topViewController(controller: navigationVC.visibleViewController)
        } else if let tabController = controller as? UITabBarController {
            if let selected = tabController.selectedViewController {
                return topViewController(controller: selected)
            }
        } else if let presented = controller?.presentedViewController {
            return topViewController(controller: presented)
        }
        return controller
    }
}
