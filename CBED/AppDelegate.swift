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
    // V11.1.14.1: strong window reference. Was `weak var window`
    // previously — that was a regression. UIApplicationDelegate's
    // declared property is `var window: UIWindow?` (strong) for a
    // reason: the window needs to outlive any short-lived
    // AppDelegate capture. With weak, code that does
    // `appDelegate.window` from a closure would intermittently see
    // nil after the first scene connection. Restored to strong.
    //
    // Note: with the scene lifecycle, the *canonical* window lives
    // on SceneDelegate. This strong ref is here so legacy
    // AppDelegate methods (logout, applyAppTheme, getCurrentVC)
    // that walk through `self.window` keep working on iOS 13+.
    var window: UIWindow?

    /// V11.1.14.1: shared singleton so the SceneDelegate (and any
    /// other module that needs push-notification hooks, theme
    /// access, etc.) can call back into AppDelegate without going
    /// through `UIApplication.shared.delegate` (which still works
    /// but is more brittle in scene-based apps).
    ///
    /// Was `weak` previously — that was wrong. UIKit owns the
    /// AppDelegate, but if something captures a weak ref and the
    /// lifetime of that capture outlives the AppDelegate (rare,
    /// but possible in scene state restoration), the `weak` ref
    /// becomes nil and downstream code crashes. Use a strong
    /// reference and trust UIKit to keep this object alive.
    static var shared: AppDelegate?

    var context = LAContext()

    // V11.1.14.1: was `private override init()`. That violates the
    // Swift rule that overriding a `required` initializer requires
    // the override itself to be `required`. UIKit on iPadOS 27
    // (and the @main expansion of UIApplicationMain) rejects this
    // silently and falls back to a path that skips our setup
    // entirely, leaving `AppDelegate.shared = nil` for the rest
    // of the app's lifetime. Marking the override `required`
    // resolves the inheritance check and keeps the call site.
    required override init() {
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
