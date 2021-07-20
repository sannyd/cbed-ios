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
import SwiftyStoreKit

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


var remoteConfig = RemoteConfig.remoteConfig()

//extension UIFontDescriptor.AttributeName {
//    static let nsctFontUIUsage = UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")
//}
//
//extension UIFont {
//
//
//    static var isOverrided: Bool = false
//
//    @objc class func mySystemFont(ofSize size: CGFloat) -> UIFont {
//        return UIFont(name: Constants.Font.LatoRegular, size: size)!
//    }
//
//    @objc class func myBoldSystemFont(ofSize size: CGFloat) -> UIFont {
//        return UIFont(name: Constants.Font.LatoBold, size: size)!
//    }
//
////    @objc class func myPreferredFont() -> UIFont {
////        let scaledFont = ScaledFont(fontName: Constants.Font.LatoRegular)
////        return UIFont.preferredFont(forTextStyle: .body)
////    }
//
//    @objc convenience init(myCoder aDecoder: NSCoder) {
//        guard
//            let fontDescriptor = aDecoder.decodeObject(forKey: "UIFontDescriptor") as? UIFontDescriptor,
//            let fontAttribute = fontDescriptor.fontAttributes[.nsctFontUIUsage] as? String else {
//                self.init(myCoder: aDecoder)
//                return
//        }
//        var fontName = ""
//        switch fontAttribute {
//        case "CTFontRegularUsage":
//            fontName = Constants.Font.LatoRegular
//        case "CTFontEmphasizedUsage", "CTFontBoldUsage":
//            fontName = Constants.Font.LatoBold
//        default:
//            fontName = Constants.Font.LatoRegular
//        }
//        self.init(name: fontName, size: fontDescriptor.pointSize)!
//    }
//
//    class func overrideInitialize() {
//        guard self == UIFont.self, !isOverrided else { return }
//
//        // Avoid method swizzling run twice and revert to original initialize function
//        isOverrided = true
//
//        if let systemFontMethod = class_getClassMethod(self, #selector(systemFont(ofSize:))),
//            let mySystemFontMethod = class_getClassMethod(self, #selector(mySystemFont(ofSize:))) {
//            method_exchangeImplementations(systemFontMethod, mySystemFontMethod)
//        }
//
//        if let boldSystemFontMethod = class_getClassMethod(self, #selector(boldSystemFont(ofSize:))),
//            let myBoldSystemFontMethod = class_getClassMethod(self, #selector(myBoldSystemFont(ofSize:))) {
//            method_exchangeImplementations(boldSystemFontMethod, myBoldSystemFontMethod)
//        }
//
//        if let initCoderMethod = class_getInstanceMethod(self, #selector(UIFontDescriptor.init(coder:))), // Trick to get over the lack of UIFont.init(coder:))
//            let myInitCoderMethod = class_getInstanceMethod(self, #selector(UIFont.init(myCoder:))) {
//            method_exchangeImplementations(initCoderMethod, myInitCoderMethod)
//        }
//    }
//}

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        RxImagePickerDelegateProxy.register { RxImagePickerDelegateProxy(imagePicker: $0) }
        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
            FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {

            do {
                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
                print(receiptData)

                let receiptString = receiptData.base64EncodedString(options: [])
                Log.d(receiptString)
                // Read receiptData
            }
            catch { print("Couldn't read receipt data with error: " + error.localizedDescription) }
        }
        
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
        
//        UIFont.overrideInitialize()
        
        FirebaseApp.configure()
        fetchRemoteConfig()
        
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
            GIDSignIn.sharedInstance.handle(url)
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

