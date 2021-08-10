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
                        
                        if Storage.accessToken == nil {
                            if isEnableLogin {
                                self.goToLogin()
                            } else {
                                let tabbarVC = StoryboardManager.instanceTabBarVC()
                                appDelegate.window?.rootViewController = tabbarVC
                            }
                        } else {
                            let tabbarVC = StoryboardManager.instanceTabBarVC()
                            appDelegate.window?.rootViewController = tabbarVC
                        }
                    }
                } else {
                    Storage.removeAll()
                    self.goToLogin()
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
