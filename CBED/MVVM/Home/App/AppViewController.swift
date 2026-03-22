//
//  AppViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 23/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

final class AppViewController: UIViewController {
    
    // MARK: - IBOutlets
    
    // MARK: - Properties
    
    var viewModel: AppViewModel!
    var disposeBag = DisposeBag()
    
    private let staticToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoyMjYwMzY4NjY5LCJqdGkiOiJqa2ZoYjc4NGc5NzI4dWJyaXUyM3k0OTI4dWsiLCJ1c2VyX2lkIjoxN30.2rhFITU6xMC4qJXIip6DaFMNMkdhZ5qOilbLN-fyHz0"
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods

    private func parseRemoteBool(_ value: Any?) -> Bool? {
        switch value {
        case let bool as Bool:
            return bool
        case let number as NSNumber:
            return number.boolValue
        case let string as String:
            switch string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "true", "t", "1", "yes", "y":
                return true
            case "false", "f", "0", "no", "n":
                return false
            default:
                return nil
            }
        default:
            return nil
        }
    }

    private func showMainApp(using appDelegate: AppDelegate) {
        let tabbarVC = StoryboardManager.instanceTabBarVC()
        appDelegate.window?.rootViewController = tabbarVC
    }

    private func loadMembershipIfNeeded(using appDelegate: AppDelegate) {
#if targetEnvironment(simulator)
        print("[Remote Config] Skipping StoreKit receipt check on simulator")
        showMainApp(using: appDelegate)
#else
        print("[Remote Config] getLastReceipt start")
        StoreKitService.shared.getLastReceipt { receipt in
            print("[Remote Config] getLastReceipt finish")
            if let receipt = receipt {
                print("[Remote Config] verifyReceipt start")
                StoreKitService.shared.verifyReceipt(receipt, completion: { isPurchased, monthType in
                    print("[Remote Config] verifyReceipt finish")
                    CurrentMembershipType = monthType
                    self.showMainApp(using: appDelegate)
                })
            } else {
                self.showMainApp(using: appDelegate)
            }
        }
#endif
    }
    
    func bindViewModel() {
        let input = AppViewModel.Input(firstLoadTrigger: rxViewWillAppear)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        // Change config here Sanny
        let configName = "alternative config"
        
        [output
            .loadAppTrigger
            .asDriverOnErrorJustComplete()
            .drive(onNext: { objects in
                let (isProfileInfoLoaded, remoteConfigs) = objects
                print("[Remote Config] \(remoteConfigs)")
                if isProfileInfoLoaded {
                    print("[Remote Config] Fetched")
                    
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    
                    guard let remoteConfigs = remoteConfigs?.first(where: { $0["name"] as? String == configName }) else {
                        print("[Remote Config] Missing config named: \(configName)")
                        let tabbarVC = StoryboardManager.instanceTabBarVC()
                        appDelegate.window?.rootViewController = tabbarVC
                        return
                    }
                    print("[Remote Config] Using config: \(remoteConfigs)")
                
                    guard let isEnableLogin = self.parseRemoteBool(remoteConfigs["is_enable_login"]),
                          let isEnableDeleteAccount = self.parseRemoteBool(remoteConfigs["is_enable_delete_account"]) else {
                        print("[Remote Config] Invalid flags for config: \(configName), raw is_enable_login=\(String(describing: remoteConfigs["is_enable_login"])), raw is_enable_delete_account=\(String(describing: remoteConfigs["is_enable_delete_account"]))")
                        return
                    }
                    print("[Remote Config] is_enable_login=\(isEnableLogin), is_enable_delete_account=\(isEnableDeleteAccount)")
                    IsEnableDeleteAccount = isEnableDeleteAccount
                    
                    if Storage.accessToken == nil {
                        if isEnableLogin {
                            Storage.removeAll()
                            self.goToLogin()
                        } else {
                            IsEnableLogin = isEnableLogin
                            IsEnableDeleteAccount = isEnableDeleteAccount
                            self.showMainApp(using: appDelegate)
                        }
                    } else {
                        if isEnableLogin {
                            self.showMainApp(using: appDelegate)
                        } else {
                            if Storage.accessToken == self.staticToken {
                                IsEnableLogin = isEnableLogin
                                IsEnableDeleteAccount = isEnableDeleteAccount
                                self.loadMembershipIfNeeded(using: appDelegate)
                            } else {
                                self.showMainApp(using: appDelegate)
                            }
                        }
                    }
                } else {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    
                    guard let remoteConfigs = remoteConfigs?.first(where: { $0["name"] as? String == configName }) else {
                        print("[Remote Config] Missing config named: \(configName)")
                        let tabbarVC = StoryboardManager.instanceTabBarVC()
                        appDelegate.window?.rootViewController = tabbarVC
                        return
                    }
                    print("[Remote Config] Using config: \(remoteConfigs)")
                
                    guard let isEnableLogin = self.parseRemoteBool(remoteConfigs["is_enable_login"]),
                          let isEnableDeleteAccount = self.parseRemoteBool(remoteConfigs["is_enable_delete_account"]) else {
                              print("[Remote Config] Invalid flags for config: \(configName), raw is_enable_login=\(String(describing: remoteConfigs["is_enable_login"])), raw is_enable_delete_account=\(String(describing: remoteConfigs["is_enable_delete_account"]))")
                              Storage.removeAll()
                              self.goToLogin()
                              return
                    }
                    print("[Remote Config] is_enable_login=\(isEnableLogin), is_enable_delete_account=\(isEnableDeleteAccount)")
                    IsEnableLogin = isEnableLogin
                    IsEnableDeleteAccount = isEnableDeleteAccount
                    if isEnableLogin {
                        Storage.removeAll()
                        self.goToLogin()
                    } else {
                        Storage.accessToken = self.staticToken
                        self.loadMembershipIfNeeded(using: appDelegate)
                    }
                }
            }),
        output
            .isLoading
            .asDriverOnErrorJustComplete()
            .drive(LoadingIndicatorView.rx.isAnimating)]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func goToLogin() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let loginVC = StoryboardManager.instanceLoginVC()
        let nav = UINavigationController(rootViewController: loginVC)
        loginVC.viewModel = .init(useCase: LoginUseCase(),
                                  navigator: LoginNavigator(window: appDelegate.window!,
                                                            navigationController: nav))
        appDelegate.window?.rootViewController = nav
    }
}
