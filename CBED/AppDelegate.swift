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
    // V11.1.14: weak window — the actual UIWindow now lives on
    // SceneDelegate. We keep a weak reference here so legacy
    // helpers (logout, getCurrentViewController) that go through
    // `AppDelegate.shared?.window` still work in iOS < 13 fallback
    // and during the brief window between app launch and scene
    // connection.
    weak var window: UIWindow?

    /// V11.1.14: shared singleton so the SceneDelegate (and any
    /// other module that needs push-notification hooks, theme
    /// access, etc.) can call back into AppDelegate without going
    /// through `UIApplication.shared.delegate` (which still works
    /// but is more brittle in scene-based apps).
    static weak var shared: AppDelegate?

    var context = LAContext()

    private override init() {
        super.init()
        AppDelegate.shared = self
    }

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

        // V11.1.14: window + root view controller setup moved to
        // SceneDelegate.scene(_:willConnectTo:options:) — required
        // for iOS 13+ scene lifecycle compliance (Guideline 2.1(a),
        // iPadOS 27 reviewer crash). The legacy `var window: UIWindow?`
        // descriptor remains above so legacy helpers that read
        // `AppDelegate.shared?.window` keep working.

        return true
    }

    // MARK: - UISceneSession Lifecycle (V11.1.14)

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Match the "Default Configuration" declared in Info.plist's
        // UIApplicationSceneManifest. Returning by name lets UIKit
        // instantiate our SceneDelegate without any extra plumbing.
        return UISceneConfiguration(name: "Default Configuration",
                                    sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication,
                     didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // No-op. We don't hold per-scene state worth releasing here,
        // but the method must exist to satisfy the UISceneDelegate
        // contract now that the app advertises a scene manifest.
    }

    // MARK: - Scene-shimmed helpers (V11.1.14)

    /// Window-aware theme applier. Called from SceneDelegate so the
    /// window it creates picks up the saved theme on first paint.
    func applyAppThemeToWindow(_ window: UIWindow) {
        window.overrideUserInterfaceStyle = Storage.appTheme.interfaceStyle
    }

    /// Re-entry point for the legacy applicationDidBecomeActive
    /// hook. SceneDelegate.sceneDidBecomeActive routes here so the
    /// FaceID prompt fires whether or not we ever leave the legacy
    /// window path.
    func applicationDidBecomeActiveForScene() {
        applicationDidBecomeActive(UIApplication.shared)
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
        // V11.1.14: legacy zero-arg helper kept for any caller that
        // still goes through it (search the project — there are a
        // few). Forwards to the window-aware variant when a window
        // exists; no-ops otherwise (scene-based apps apply the
        // theme via SceneDelegate.scene(_:willConnectTo:) directly).
        guard let window = window else { return }
        applyAppThemeToWindow(window)
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
