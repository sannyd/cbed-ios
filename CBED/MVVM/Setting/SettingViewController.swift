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
    @IBOutlet weak var buttonRestorePurchase: CustomBorderButton!
    @IBOutlet weak var buttonEdit: UIButton!
    
    // MARK: - Properties
    
    var viewModel: SettingViewModel!
    var disposeBag = DisposeBag()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImageView.setRoundShape()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        buttonLogout.isHidden = !IsEnableLogin
        buttonEdit.isHidden = !IsEnableLogin
        
        if !IsEnableLogin {
            updateProfileForLoginDisable()
        }
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let viewWillAppear = rx
            .sentMessage(#selector(UIViewController.viewWillAppear))
            .mapToVoid()
        
        let input = SettingViewModel.Input(viewWillAppear: viewWillAppear,
                                           buttonRestorePurchaseTrigger: buttonRestorePurchase.rxButtonTapped,
                                           buttonEditTrigger: buttonEdit.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .profileInfo
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] profileInfo in
                let name = IsEnableLogin ? profileInfo.name : "Newcomer"
                self?.labelName.text = "Name: \(name)"
                let email = IsEnableLogin ? profileInfo.email : "N/A"
                self?.labelEmail.text = "Email: \(email)"
                self?.labelEmail.isHidden = !IsEnableLogin
                let membership = IsEnableLogin ? profileInfo.memberPlan.stringValue : (CurrentMembershipType?.name ?? "")
                self?.labelMembership.text = "Membership: \(membership)"
                self?.profileImageView.loadImage(with: profileInfo.avatar, placeholder: #imageLiteral(resourceName: "img_user_placeholder"))
            }),
         output
            .restorePurchaseSuccess
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                if !IsEnableLogin {
                    self?.updateProfileForLoginDisable()
                }
            }),
         output
            .isLoading
            .asDriverOnErrorJustComplete()
            .drive(LoadingIndicatorView.rx.isAnimating),
         output
            .error
            .asDriverOnErrorJustComplete()
            .drive(errorBinding),
         buttonLogout
            .rxButtonTapped
            .subscribe(onNext: { _ in
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.logout()
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func updateProfileForLoginDisable() {
        labelName.text = "Newcomer"
        labelMembership.text = "Membership: \(CurrentMembershipType?.name ?? "Free")"
        labelEmail.isHidden = true
        profileImageView.image = #imageLiteral(resourceName: "img_user_placeholder")
        
//        if CurrentMembershipType == nil {
//            buttonRestorePurchase.isHidden = false
//        } else {
//            buttonRestorePurchase.isHidden = true
//        }
    }
}
