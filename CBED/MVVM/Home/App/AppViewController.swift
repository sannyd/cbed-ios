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

    // V11.1.13: dropped the hardcoded "alternative config" name
    // preference. Selection now follows the backend's is_default flag
    // exclusively (with a first-entry fallback for safety). This makes
    // the active config dynamic — flipping is_default on a row in the
    // Django admin is now sufficient to switch what the iOS app picks,
    // with no rebuild required.
    private let preferredRemoteConfigName: String? = nil
    
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

    private func selectedRemoteConfig(from remoteConfigs: [[String: Any]]?) -> [String: Any]? {
        // V11.1.15 (Build 5 — Guideline 2.1(a) fix):
        // Guaranteed non-nil when *any* configs array is provided.
        // Three-step fallback chain:
        //   1. Optional preferred name (preferredRemoteConfigName), if set
        //   2. First config whose is_default parses to truthy
        //   3. First config whose name contains "alternative" (case-insensitive)
        //   4. The very first entry
        // parseRemoteBool handles Bool, NSNumber, Int, and common string
        // forms so a type mismatch (Int 1, NSNumber 1, String "true", etc.)
        // can never cause us to skip every row and return nil.
        guard let configs = remoteConfigs, !configs.isEmpty else { return nil }

        // 1. Explicit preferred name
        if let preferred = preferredRemoteConfigName,
           !preferred.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let named = configs.first(where: {
                ($0["name"] as? String)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased() == preferred.lowercased()
            }) {
                return named
            }
        }

        // 2. Backend's is_default flag (type-resilient)
        if let defaultConfig = configs.first(where: {
            parseRemoteBool($0["is_default"]) == true
        }) {
            return defaultConfig
        }

        // 3. Name-based heuristic: a config whose name contains "alternative"
        if let altConfig = configs.first(where: {
            ($0["name"] as? String)?
                .lowercased()
                .contains("alternative") == true
        }) {
            return altConfig
        }

        // 4. Absolute fallback: first entry. The presence of any configs
        // array at all is enough to proceed; this is a defensive net.
        return configs.first
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
        
        [output
            .loadAppTrigger
            .asDriverOnErrorJustComplete()
            .drive(onNext: { objects in
                let (isProfileInfoLoaded, remoteConfigs) = objects
                print("[Remote Config] \(remoteConfigs)")
                if isProfileInfoLoaded {
                    print("[Remote Config] Fetched")

                    let appDelegate = UIApplication.shared.delegate as! AppDelegate

                    guard let remoteConfigs = self.selectedRemoteConfig(from: remoteConfigs) else {
                        print("[Remote Config] Missing selected config")
                        let tabbarVC = StoryboardManager.instanceTabBarVC()
                        appDelegate.window?.rootViewController = tabbarVC
                        return
                    }
                    print("[Remote Config] Using config: \(remoteConfigs)")

                    // V11.1.15 (Build 5 — Guideline 2.1(a) fix):
                    // If either flag is missing or unparseable, fall back to
                    // SAFE DEFAULTS (isEnableLogin=false, isEnableDeleteAccount=false)
                    // and proceed. Bailing out here leaves the spinner running
                    // forever, which is exactly what App Review rejected.
                    let isEnableLogin = self.parseRemoteBool(remoteConfigs["is_enable_login"]) ?? false
                    let isEnableDeleteAccount = self.parseRemoteBool(remoteConfigs["is_enable_delete_account"]) ?? false
                    print("[Remote Config] is_enable_login=\(isEnableLogin), is_enable_delete_account=\(isEnableDeleteAccount) (raw is_enable_login=\(String(describing: remoteConfigs["is_enable_login"])), raw is_enable_delete_account=\(String(describing: remoteConfigs["is_enable_delete_account"])))")
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

                    guard let remoteConfigs = self.selectedRemoteConfig(from: remoteConfigs) else {
                        print("[Remote Config] Missing selected config (unauthenticated state) — routing to login")
                        Storage.removeAll()
                        self.goToLogin()
                        return
                    }
                    print("[Remote Config] Using config: \(remoteConfigs)")

                    // V11.1.15 (Build 5 — Guideline 2.1(a) fix):
                    // Same hardening as the authenticated branch — fall back
                    // to safe defaults rather than bailing out. In the
                    // unauthenticated state, the safe default is to assume
                    // login IS required (true), which keeps the user on the
                    // login screen rather than leaving the spinner running.
                    let isEnableLogin = self.parseRemoteBool(remoteConfigs["is_enable_login"]) ?? true
                    let isEnableDeleteAccount = self.parseRemoteBool(remoteConfigs["is_enable_delete_account"]) ?? false
                    print("[Remote Config] is_enable_login=\(isEnableLogin), is_enable_delete_account=\(isEnableDeleteAccount) (raw is_enable_login=\(String(describing: remoteConfigs["is_enable_login"])), raw is_enable_delete_account=\(String(describing: remoteConfigs["is_enable_delete_account"])))")
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
