//
//  AppDelegate.swift
//  CBED
//
//  Created by Jimmy Hoang on 06/06/2021.
//

import UIKit
import GoogleSignIn
//import FBSDKCoreKit
//import FBSDKLoginKit
import IQKeyboardManagerSwift
import Firebase
import SwiftyStoreKit
import LocalAuthentication

#if os(iOS)

import RxSwift
import RxCocoa
import UIKit

open class RxImagePickerDelegateProxy
    : RxNavigationControllerDelegateProxy, UIImagePickerControllerDelegate {

    public init(imagePicker: UIImagePickerController) {
        super.init(navigationController: imagePicker)
    }

}

#endif

var IsEnableLogin = true
var IsEnableDeleteAccount = false
var CurrentMembershipType: InAppPurchaseMonth?

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    var context = LAContext()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
 
        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        
        RxImagePickerDelegateProxy.register { RxImagePickerDelegateProxy(imagePicker: $0) }

        SwiftyStoreKit.completeTransactions(atomically: true) { purchases in
            // ... other code here
            for purchase in purchases {
                switch purchase.transaction.transactionState {
                case .purchased, .restored:
                    if purchase.needsFinishTransaction {
                        // Deliver content from server, then:
                        SwiftyStoreKit.finishTransaction(purchase.transaction)
                    }
      
                // Unlock content
                case .failed, .purchasing, .deferred:
                    break // do nothing
                }
            }
        }
 
        FirebaseApp.configure()
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.keyboardDistanceFromTextField = 120
        
        let window = UIWindow(frame: UIScreen.main.bounds)
        self.window = window
        applyAppTheme()
        
        let appVC: AppViewController = StoryboardManager.getVCFromHomeSB()
        appVC.viewModel = .init(useCase: AppUseCase(), navigator: AppNavigator())
        window.rootViewController = appVC
        window.makeKeyAndVisible()
        
        return true
    }
    
    func applicationDidBecomeActive(_ app: UIApplication) {
        if Storage.isEnableFaceID {
            if let faceIDExpireDate = Storage.faceIDExpireDate {
                if Date() > faceIDExpireDate {
                    checkFaceID()
                }
            } else {
                checkFaceID()
            }
        }
    }
    
    private func checkFaceID() {
        context = LAContext()

        // First check if we have the needed hardware support.
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {

            let reason = "To use the app"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in

                if success {
                    let currentDate = Date()
                    Storage.faceIDExpireDate = Calendar.current.date(byAdding: .minute, value: 1, to: currentDate)
                    print("Success oh year")
                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")

                    // Fall back to a asking for username and password.
                    // ...
                }
            }
        } else {
            print(error?.localizedDescription ?? "Can't evaluate policy")

            // Fall back to a asking for username and password.
            // ...
        }
    }
    
    func getCurrentViewController() -> UIViewController {
        return window!.visibleViewController!
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        GIDSignIn.sharedInstance.handle(url)
    }
    
    func applyAppTheme() {
        window?.overrideUserInterfaceStyle = Storage.appTheme.interfaceStyle
    }
    
    func logout() {
        guard let window = window else {
            return
        }
        
        Storage.removeAll()
        
        let loginVC = StoryboardManager.instanceLoginVC()
        let nav = UINavigationController(rootViewController: loginVC)
        loginVC.viewModel = .init(useCase: LoginUseCase(),
                                  navigator: LoginNavigator(window: window,
                                                            navigationController: nav))
        window.rootViewController = nav
        window.makeKeyAndVisible()
    }
}
