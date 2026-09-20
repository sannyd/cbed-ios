//
//  UIApplication+Extensions.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 11/11/19.
//  Copyright © 2019 Advesa. All rights reserved.
//

import UIKit

extension UIApplication {
    /// V11.1.14.1: scene-aware keyWindow accessor. On iPadOS 27 /
    /// iOS 27 the legacy `UIApplication.shared.keyWindow` is
    /// nil during scene setup and immediately after multi-window
    /// transitions. Walk the connected scenes and pick the first
    /// key window we find. Falls back to `.windows.first` if no
    /// scene has gone key yet (e.g. in tests).
    public static var sceneKeyWindow: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            if let key = ws.windows.first(where: { $0.isKeyWindow }) {
                return key
            }
            if let any = ws.windows.first {
                return any
            }
        }
        return nil
    }

    public static func topViewController(controller: UIViewController? = UIApplication.sceneKeyWindow?.rootViewController) -> UIViewController? {
        
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
