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
import IQKeyboardManagerSwift
import Firebase

var remoteConfig = RemoteConfig.remoteConfig()

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        FirebaseApp.configure()
        fetchRemoteConfig()
        
        GIDSignIn.sharedInstance().clientID = "660482726170-lbmu7vtnugfrm6tb03oetv44361v7tci.apps.googleusercontent.com"
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 120
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        
        let appVC: AppViewController = StoryboardManager.getVCFromHomeSB()
        appVC.viewModel = .init(useCase: AppUseCase(), navigator: AppNavigator())
        window.rootViewController = appVC
        window.makeKeyAndVisible()
        
        return true
    }
    
    func fetchRemoteConfig() {
        remoteConfig.fetch(withExpirationDuration: 100) { [unowned self] (status, error) in
            guard error == nil else { return }
            remoteConfig.activate()
        }
    }
    
    func getCurrentViewController() -> UIViewController {
        return window!.visibleViewController!
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return FBSDKCoreKit.ApplicationDelegate.shared.application(app, open: url, options: options) ||
            GIDSignIn.sharedInstance().handle(url)
    }
    
    func logout() {
        guard let window = window else {
            return
        }
        
        Storage.removeAll()
        
        let loginVC = StoryboardManager.instanceLoginVC()
        let nav = UINavigationController(rootViewController: loginVC)
        loginVC.viewModel = .init(useCase: LoginUseCase(), navigator: LoginNavigator(window: window))
        window.rootViewController = nav
        window.makeKeyAndVisible()
    }
}

