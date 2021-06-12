//
//  AppDelegate.swift
//  CBED
//
//  Created by Jimmy Hoang on 06/06/2021.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func getCurrentViewController() -> UIViewController {
        return window!.visibleViewController!
    }
}

