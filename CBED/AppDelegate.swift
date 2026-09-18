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
import FirebaseCrashlytics
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

        // V11.1: register app-level UserDefaults so any first-launch
        // reader that uses UserDefaults directly (rather than
        // `Storage.examLocation`) still sees MPRE as the default
        // exam jurisdiction. Mirrors `ExamLocation.defaultLocation = .mpre`.
        UserDefaults.standard.register(defaults: [
            "exam_location": ExamLocation.defaultLocation.rawValue,
        ])

        context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        UIButton.installTapFeedbackSwizzle()
        AudioFeedbackManager.shared.prepare()
        
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
        // Wire up Crashlytics: route every uncaught NSException to it so we get
        // real stack traces (instead of just GA4 app_exception counts).
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
        NSSetUncaughtExceptionHandler { exception in
            let nsError = NSError(
                domain: exception.name.rawValue,
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: exception.reason ?? "n/a",
                           "stackTrace": exception.callStackSymbols.joined(separator: "\n")]
            )
            Crashlytics.crashlytics().record(error: nsError)
        }

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
    
    func getCurrentViewController() -> UIViewController? {
        guard let window = window else { return nil }
        var vc = window.rootViewController
        while let presented = vc?.presentedViewController {
            vc = presented
        }
        return vc
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
        // Clear Firebase Analytics user ID so post-logout sessions are anonymous
        Analytics.setUserID(nil)

        let loginVC = StoryboardManager.instanceLoginVC()
        let nav = UINavigationController(rootViewController: loginVC)
        loginVC.viewModel = .init(useCase: LoginUseCase(),
                                  navigator: LoginNavigator(window: window,
                                                            navigationController: nav))
        window.rootViewController = nav
        window.makeKeyAndVisible()
    }
}
