//
//  SettingViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

final class SettingViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelEmail: UILabel!
    @IBOutlet weak var labelMembership: UILabel!
    @IBOutlet weak var buttonLogout: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    // MARK: - Properties
    
    var viewModel: SettingViewModel!
    var disposeBag = DisposeBag()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let input = SettingViewModel.Input()
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .profileInfo
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] profileInfo in
                self?.labelName.text = profileInfo.name
                self?.labelEmail.text = profileInfo.email
                self?.labelMembership.text = profileInfo.membership
                self?.profileImageView.loadImage(with: profileInfo.avatar)
            }),
         buttonLogout
             .rxButtonTapped
             .subscribe(onNext: { _ in
                 let appDelegate = UIApplication.shared.delegate as! AppDelegate
                 appDelegate.logout()
             })]
            .forEach { $0.disposed(by: disposeBag) }
    }
}
