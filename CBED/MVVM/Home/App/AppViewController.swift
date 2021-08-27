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
            .drive(onNext: { isProfileInfoLoaded in
                if isProfileInfoLoaded {
                    remoteConfig.fetch(withExpirationDuration: 0) { [unowned self] (status, error) in
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        
                        guard error == nil else {
                            let tabbarVC = StoryboardManager.instanceTabBarVC()
                            appDelegate.window?.rootViewController = tabbarVC
                            return
                        }
                        remoteConfig.activate()
                        
                        let remoteConfigData = remoteConfig.configValue(forKey: "remote_configs").dataValue
                    
                        guard let remoteConfigs = try? JSONSerialization.jsonObject(with: remoteConfigData,
                                                                                    options: .mutableContainers) as? [String: Any],
                              let isEnableLogin = remoteConfigs["is_enable_login"] as? Bool else {
                            return
                        }
                        IsEnableLogin = isEnableLogin
                        if Storage.accessToken == nil {
                            if isEnableLogin {
                                Storage.removeAll()
                                self.goToLogin()
                            } else {
                                let tabbarVC = StoryboardManager.instanceTabBarVC()
                                appDelegate.window?.rootViewController = tabbarVC
                            }
                        } else {
                            if isEnableLogin {
                                Storage.removeAll()
                                self.goToLogin()
                            } else {
                                StoreKitService.shared.getLastReceipt { receipt in
                                    if let receipt = receipt {
                                        StoreKitService.shared.verifyReceipt(receipt, completion: { isPurchased, monthType in
                                            CurrentMembershipType = monthType
                                            
                                            let tabbarVC = StoryboardManager.instanceTabBarVC()
                                            appDelegate.window?.rootViewController = tabbarVC
                                            
                                        })
                                    }
                                }
                            }
                        }
                    }
                } else {
                    remoteConfig.fetch(withExpirationDuration: 0) { [unowned self] (status, error) in
                        let appDelegate = UIApplication.shared.delegate as! AppDelegate
                        
                        guard error == nil else {
                            let tabbarVC = StoryboardManager.instanceTabBarVC()
                            appDelegate.window?.rootViewController = tabbarVC
                            return
                        }
                        remoteConfig.activate()
                        
                        let remoteConfigData = remoteConfig.configValue(forKey: "remote_configs").dataValue
                    
                        guard let remoteConfigs = try? JSONSerialization.jsonObject(with: remoteConfigData,
                                                                                    options: .mutableContainers) as? [String: Any],
                              let isEnableLogin = remoteConfigs["is_enable_login"] as? Bool else {
                            Storage.removeAll()
                            self.goToLogin()
                            return
                        }
                        IsEnableLogin = isEnableLogin
                        if isEnableLogin {
                            Storage.removeAll()
                            self.goToLogin()
                        } else {
                            Storage.accessToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoyMjYwMzY4NjY5LCJqdGkiOiJqa2ZoYjc4NGc5NzI4dWJyaXUyM3k0OTI4dWsiLCJ1c2VyX2lkIjoxN30.2rhFITU6xMC4qJXIip6DaFMNMkdhZ5qOilbLN-fyHz0"
                            
                            StoreKitService.shared.getLastReceipt { receipt in
                                if let receipt = receipt {
                                    StoreKitService.shared.verifyReceipt(receipt, completion: { isPurchased, monthType in
                                        CurrentMembershipType = monthType
                                        
                                        let tabbarVC = StoryboardManager.instanceTabBarVC()
                                        appDelegate.window?.rootViewController = tabbarVC
                                        
                                    })
                                }
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
