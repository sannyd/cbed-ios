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
    case mpre = "MPRE"
    case florida = "Florida"
    case california = "California"
    case georgia = "Georgia"
    
    var searchLevelID: Int {
        switch self {
        case .ube:
            return 7
        case .mpre:
            return 17
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
            return [5, 7, 11, 19, 8]
        case .mpre:
            return [8, 17]
        case .florida:
            return [5, 4, 13, 8]
        case .california:
            return [5, 9, 10, 15, 8]
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
    @IBOutlet weak var notificationTestSwitch: UISwitch!
    @IBOutlet weak var appIconTestSwitch: UISwitch!
    @IBOutlet weak var appearanceSegmentedControl: UISegmentedControl!
    @IBOutlet weak var examLocationMenu: SwiftyMenu!
    
    @IBOutlet weak var essayTextfield: UITextField!
    @IBOutlet weak var mptTextfield: UITextField!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var countContainerView: UIView!
    
    
    // MARK: - Properties
    
    var viewModel: SettingViewModel!
    var disposeBag = DisposeBag()
    private var codeMenuAttributes = SwiftyMenuAttributes()
    private let dropDownOptionsDataSource = ExamLocation.allCases
    
    private let essayPickerView = UIPickerView()
    private let mptPickerView = UIPickerView()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        essayTextfield.inputView = essayPickerView
        mptTextfield.inputView = mptPickerView
        profileImageView.setRoundShape()
        notificationTestSwitch.isOn = Storage.isNotificationTestingEnabled
        appIconTestSwitch.isOn = Storage.isAppIconTestingEnabled
        appearanceSegmentedControl.selectedSegmentIndex = Storage.appTheme.rawValue
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
        codeMenuAttributes.rowStyle = .value(height: 44,
                                             backgroundColor: .secondarySystemBackground,
                                             selectedColor: .secondarySystemBackground)
        codeMenuAttributes.roundCorners = .all(radius: 8)
        codeMenuAttributes.border = .value(color: .separator, width: 0.5)
        codeMenuAttributes.textStyle = .value(color: .label,
                                              separator: ", ",
                                              font: UIFont(name: Constants.Font.LatoRegular, size: 14))
        codeMenuAttributes.placeHolderStyle = .value(text: Storage.examLocation.rawValue, textColor: .label)
        codeMenuAttributes.separatorStyle = .value(color: .separator, isBlured: true, style: .singleLine)
        codeMenuAttributes.headerStyle = .value(backgroundColor: .secondarySystemBackground, height: 44)
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
        let essayStart = BehaviorSubject<Int>(value: 0)
        let mptStart = PublishSubject<Int>()
        
        let viewWillAppear = rx
            .sentMessage(#selector(UIViewController.viewWillAppear))
            .mapToVoid()
        
        let essayCount = Observable.merge(essayPickerView.rx.modelSelected(Int.self).map { $0.first ?? 0}.asObservable(),
                                          essayStart.asObservable())
            .do(onNext: { [weak self] number in
                self?.essayTextfield.text = "\(number)"
            })
        
            .asObservable()
        let mptcount = Observable.merge(mptPickerView.rx.modelSelected(Int.self).map { $0.first ?? 0}.asObservable(),
                                        mptStart.asObservable())
            .do(onNext: { [weak self] number in
                self?.mptTextfield.text = "\(number)"
            })
            .asObservable()
        let buttonSaveTrigger = buttonSave.rxButtonTapped
            .withLatestFrom(Observable.combineLatest(essayCount, mptcount))
        //            .map { [weak self] _ in (Int(self?.essayTextfield.text ?? "0") ?? 0, Int(self?.mptTextfield.text ?? "0") ?? 0) }
        
        let input = SettingViewModel.Input(viewWillAppear: viewWillAppear,
                                           buttonRestorePurchaseTrigger: buttonRestorePurchase.rxButtonTapped,
                                           buttonEditTrigger: buttonEdit.rxButtonTapped,
                                           buttonDeactivateTrigger: buttonDeactivate.rxButtonTapped,
                                           buttonSaveTrigger: buttonSaveTrigger
        )
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
                essayStart.onNext(profileInfo.essayCount)
                mptStart.onNext(profileInfo.mptCount)
                self?.countContainerView.isHidden = !profileInfo.isTutor
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
         output
            .essaysPickerData
            .asDriverOnErrorJustComplete()
            .drive(essayPickerView.rx.itemTitles){ _, item in
                return "\(item)"
            },
         output
            .mptPickerData
            .asDriverOnErrorJustComplete()
            .drive(mptPickerView.rx.itemTitles){ _, item in
                return "\(item)"
            },
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
            }),
         notificationTestSwitch
            .rx
            .isOn
            .skip(1)
            .subscribe(onNext: { isEnabled in
                Storage.isNotificationTestingEnabled = isEnabled
                NotificationScheduler.shared.applyTestingMode(isEnabled: isEnabled)
            }),
         appIconTestSwitch
            .rx
            .isOn
            .skip(1)
            .subscribe(onNext: { isEnabled in
                Storage.isAppIconTestingEnabled = isEnabled
                AppIconManager.shared.applyTestingMode(isEnabled: isEnabled)
            }),
         appearanceSegmentedControl
            .rx
            .selectedSegmentIndex
            .skip(1)
            .compactMap(AppTheme.init(rawValue:))
            .subscribe(onNext: { theme in
                Storage.appTheme = theme
                let appDelegate = UIApplication.shared.delegate as? AppDelegate
                appDelegate?.applyAppTheme()
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
