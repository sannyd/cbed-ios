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
                    
                    guard let remoteConfigs else {
                        let tabbarVC = StoryboardManager.instanceTabBarVC()
                        appDelegate.window?.rootViewController = tabbarVC
                        return
                    }
                
                    guard let isEnableLogin = remoteConfigs["is_enable_login"] as? Bool,
                          let isEnableDeleteAccount = remoteConfigs["is_enable_delete_account"] as? Bool else {
                        return
                    }
                    IsEnableDeleteAccount = isEnableDeleteAccount
                    
                    if Storage.accessToken == nil {
                        if isEnableLogin {
                            Storage.removeAll()
                            self.goToLogin()
                        } else {
                            IsEnableLogin = isEnableLogin
                            IsEnableDeleteAccount = isEnableDeleteAccount
                            let tabbarVC = StoryboardManager.instanceTabBarVC()
                            appDelegate.window?.rootViewController = tabbarVC
                        }
                    } else {
                        if isEnableLogin {
                            let tabbarVC = StoryboardManager.instanceTabBarVC()
                            appDelegate.window?.rootViewController = tabbarVC
                        } else {
                            if Storage.accessToken == self.staticToken {
                                IsEnableLogin = isEnableLogin
                                IsEnableDeleteAccount = isEnableDeleteAccount
                                
                                print("[Remote Config] getLastReceipt start")
                                StoreKitService.shared.getLastReceipt { receipt in
                                    
                                    print("[Remote Config] getLastReceipt finish")
                                    if let receipt = receipt {
                                        
                                        print("[Remote Config] verifyReceipt start")
                                        StoreKitService.shared.verifyReceipt(receipt, completion: { isPurchased, monthType in
                                            
                                            print("[Remote Config] verifyReceipt finish")
                                            CurrentMembershipType = monthType
                                            
                                            let tabbarVC = StoryboardManager.instanceTabBarVC()
                                            appDelegate.window?.rootViewController = tabbarVC
                                        })
                                    } else {
                                        let tabbarVC = StoryboardManager.instanceTabBarVC()
                                        appDelegate.window?.rootViewController = tabbarVC
                                    }
                                }
                            } else {
                                let tabbarVC = StoryboardManager.instanceTabBarVC()
                                appDelegate.window?.rootViewController = tabbarVC
                            }
                        }
                    }
                } else {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    
                    guard let remoteConfigs else {
                        let tabbarVC = StoryboardManager.instanceTabBarVC()
                        appDelegate.window?.rootViewController = tabbarVC
                        return
                    }
                
                    guard let isEnableLogin = remoteConfigs["is_enable_login"] as? Bool,
                          let isEnableDeleteAccount = remoteConfigs["is_enable_delete_account"] as? Bool else {
                              Storage.removeAll()
                              self.goToLogin()
                              return
                    }
                    IsEnableLogin = isEnableLogin
                    IsEnableDeleteAccount = isEnableDeleteAccount
                    if isEnableLogin {
                        Storage.removeAll()
                        self.goToLogin()
                    } else {
                        Storage.accessToken = self.staticToken
                        
                        StoreKitService.shared.getLastReceipt { receipt in
                            if let receipt = receipt {
                                StoreKitService.shared.verifyReceipt(receipt, completion: { isPurchased, monthType in
                                    CurrentMembershipType = monthType
                                    
                                    let tabbarVC = StoryboardManager.instanceTabBarVC()
                                    appDelegate.window?.rootViewController = tabbarVC
                                    
                                })
                            } else {
                                let tabbarVC = StoryboardManager.instanceTabBarVC()
                                appDelegate.window?.rootViewController = tabbarVC
                            }
                        }
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
