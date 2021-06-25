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
        
        remoteConfig.fetch(withExpirationDuration: 0) { [unowned self] (status, error) in
            guard error == nil else {
                //                self.showAlert(title: USER_ERROR_TITLE, message: error?.localizedDescription ?? "")
                return
            }
            remoteConfig.activate()
            
            let remoteConfigData = remoteConfig.configValue(forKey: "remote_configs").dataValue
        
            guard let remoteConfigs = try? JSONSerialization.jsonObject(with: remoteConfigData,
                                                                        options: .mutableContainers) as? [String: Any],
                  let isEnableLogin = remoteConfigs["is_enable_login"] as? Bool else {
                return
            }
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            if Storage.accessToken == nil {
                if isEnableLogin {
                    let loginVC = StoryboardManager.instanceLoginVC()
                    let nav = UINavigationController(rootViewController: loginVC)
                    loginVC.viewModel = .init(useCase: LoginUseCase(), navigator: LoginNavigator(window: appDelegate.window!))
                    appDelegate.window?.rootViewController = nav
                } else {
                    let tabbarVC = StoryboardManager.instanceTabBarVC()
                    appDelegate.window?.rootViewController = tabbarVC
                }
            } else {
                let tabbarVC = StoryboardManager.instanceTabBarVC()
                appDelegate.window?.rootViewController = tabbarVC
            }
        }
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let input = AppViewModel.Input()
        let output = viewModel.transform(input, disposeBag: disposeBag)
    }
}
