//
//  SettingViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit
import RxSwift
import RxCocoa
import LocalAuthentication
import SwiftyMenu

enum ExamLocation: String, CaseIterable {
    case ube = "UBE JX"
    case florida = "Florida"
    case california = "California"
    case georgia = "Georgia"
    
    var searchLevelID: Int {
        switch self {
        case .ube:
            return 7
        case .florida:
            return 13
        case .california:
            return 9
        case .georgia:
            return 14
        }
    }
    
    var allowLevelIDs: [Int] {
        switch self {
        case .ube:
            return [5, 7, 11, 8]
        case .florida:
            return [5, 4, 13, 8]
        case .california:
            return [5, 9, 10, 8]
        case .georgia:
            return [5, 14, 11, 8]
        }
    }
}

extension ExamLocation: SwiftyMenuDisplayable {
    public var displayableValue: String {
        return self.rawValue
    }

    public var retrievableValue: Any {
        return self
    }
}

final class SettingViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var buttonDeactivate: CustomBorderButton!
    @IBOutlet weak var labelEmail: UILabel!
    @IBOutlet weak var labelMembership: UILabel!
    @IBOutlet weak var buttonLogout: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var buttonRestorePurchase: CustomBorderButton!
    @IBOutlet weak var buttonEdit: UIButton!
    @IBOutlet weak var faceIDSwitch: UISwitch!
    @IBOutlet weak var examLocationMenu: SwiftyMenu!
    // MARK: - Properties
    
    var viewModel: SettingViewModel!
    var disposeBag = DisposeBag()
    private var codeMenuAttributes = SwiftyMenuAttributes()
    private let dropDownOptionsDataSource = ExamLocation.allCases
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImageView.setRoundShape()
        bindViewModel()
        buttonDeactivate.isHidden = !IsEnableDeleteAccount
        setupSwiftDrawer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        buttonLogout.isHidden = !IsEnableLogin
        buttonEdit.isHidden = !IsEnableLogin
        
        if !IsEnableLogin {
            updateProfileForLoginDisable()
        }
        
        checkFaceID()
    }
    
    private func setupSwiftDrawer() {
        examLocationMenu.isUserInteractionEnabled = true
        examLocationMenu.items = dropDownOptionsDataSource
        codeMenuAttributes.multiSelect = .disabled
        codeMenuAttributes.hideOptionsWhenSelect = .enabled
        codeMenuAttributes.rowStyle = .value(height: 44, backgroundColor: .white, selectedColor: .white)
        codeMenuAttributes.roundCorners = .all(radius: 8)
        codeMenuAttributes.border = .value(color: .gray, width: 0.5)
        codeMenuAttributes.placeHolderStyle = .value(text: Storage.examLocation.rawValue, textColor: .black)
        codeMenuAttributes.separatorStyle = .value(color: .black, isBlured: true, style: .singleLine)
        codeMenuAttributes.headerStyle = .value(backgroundColor: .lightGray, height: 44)
        examLocationMenu.configure(with: codeMenuAttributes)
        
        examLocationMenu.didSelectItem = { [weak self] menu, item, index in
            guard let self else { return }
            if let examLocation = item.retrievableValue as? ExamLocation {
                Storage.examLocation = examLocation
            }
        }
    }
    
    private func checkFaceID() {
        let context = LAContext()
        
        //        context.localizedCancelTitle = "Enter Username/Password"
        
        // First check if we have the needed hardware support.
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            faceIDSwitch.isEnabled = true
            faceIDSwitch.isOn = Storage.isEnableFaceID
        } else {
            faceIDSwitch.isEnabled = false
            Storage.isEnableFaceID = false
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
                                           buttonEditTrigger: buttonEdit.rxButtonTapped,
                                           buttonDeactivateTrigger: buttonDeactivate.rxButtonTapped)
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
            .deactivateSuccess
            .asDriverOnErrorJustComplete()
            .drive(onNext: { _ in
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.logout()
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
        }),
         faceIDSwitch
            .rx
            .isOn
            .skip(1)
            .subscribe(onNext: { isEnableFaceID in
            Storage.isEnableFaceID = isEnableFaceID
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
