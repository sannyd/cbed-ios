//
//  AppDelegate.swift
//  CBED
//
//  Created by Jimmy Hoang on 06/06/2021.
//

import UIKit
import GoogleSignIn
import FBSDKCoreKit
import FBSDKLoginKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GIDSignIn.sharedInstance().clientID = "660482726170-lbmu7vtnugfrm6tb03oetv44361v7tci.apps.googleusercontent.com"
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        let loginVC = StoryboardManager.instanceLoginVC()
        let nav = UINavigationController(rootViewController: loginVC)
        loginVC.viewModel = .init(useCase: LoginUseCase(), navigator: LoginNavigator(window: window))
        window.rootViewController = nav
        window.makeKeyAndVisible()
        
        return true
    }
    
    func getCurrentViewController() -> UIViewController {
        return window!.visibleViewController!
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return FBSDKCoreKit.ApplicationDelegate.shared.application(app, open: url, options: options) ||
            GIDSignIn.sharedInstance().handle(url)
    }
}

