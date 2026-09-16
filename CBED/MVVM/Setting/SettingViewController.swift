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
    case nextGen = "NextGen"

    // TODO: Change to true for Version 11.0 release to reveal NextGen.
    static let isNextGenEnabled = true

    static let defaultLocation: ExamLocation = .mpre

    static var selectableLocations: [ExamLocation] {
        allCases.filter { isNextGenEnabled || $0 != .nextGen }
    }

    var isSelectable: Bool {
        Self.selectableLocations.contains(self)
    }
    
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
        case .nextGen:
            return 8
        }
    }

    var homeSearchTitle: String {
        switch self {
        case .mpre:
            return "Search MPRE Qs"
        case .nextGen:
            return "Search NextGen"
        case .georgia:
            return "Search Georgia Essays"
        default:
            return "Search Essays"
        }
    }
    
    var allowLevelIDs: [Int] {
        switch self {
        case .ube:
            return [5, 40, 7, 11, 19, 8]
        case .mpre:
            return [8, 17]
        case .florida:
            return [5, 40, 4, 13, 8]
        case .california:
            return [5, 40, 9, 10, 15, 8]
        case .georgia:
            return [5, 40, 14, 11, 8]
        case .nextGen:
            return [5, 40, 8, 29, 30, 31, 33, 34, 35]
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
    @IBOutlet weak var soundEffectsSwitch: UISwitch!
    @IBOutlet weak var appearanceSegmentedControl: UISegmentedControl!
    @IBOutlet weak var fontSizeTextfield: UITextField!
    @IBOutlet weak var examLocationMenu: SwiftyMenu!
    
    @IBOutlet weak var essayTextfield: UITextField!
    @IBOutlet weak var mptTextfield: UITextField!
    @IBOutlet weak var buttonSave: UIButton!
    @IBOutlet weak var countContainerView: UIView!
    
    
    // MARK: - Properties
    
    var viewModel: SettingViewModel!
    var disposeBag = DisposeBag()
    private var codeMenuAttributes = SwiftyMenuAttributes()
    private let dropDownOptionsDataSource = ExamLocation.selectableLocations
    /// rootView → parent.safeAreaLayoutGuide pinning, installed lazily
    /// inside `viewWillLayoutSubviews` once `view.superview` is non-nil.
    /// Tracked so we install exactly once per Settings-instance lifetime.
    private var rootViewConstraints: [NSLayoutConstraint] = []
    
    private let essayPickerView = UIPickerView()
    private let mptPickerView = UIPickerView()
    private let fontSizePickerView = UIPickerView()
    private let fontSizeOptionsDataSource = AppFontSize.allCases
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureScrollableLayout()
        configurePickerTextField(essayTextfield, inputView: essayPickerView)
        configurePickerTextField(mptTextfield, inputView: mptPickerView)
        configurePickerTextField(fontSizeTextfield, inputView: fontSizePickerView)
        profileImageView.setRoundShape()
        soundEffectsSwitch.isOn = Storage.isButtonSoundEnabled
        appearanceSegmentedControl.selectedSegmentIndex = Storage.appTheme.rawValue
        fontSizeTextfield.text = Storage.appFontSize.title
        fontSizeTextfield.applyAppFontScaling()
        if let selectedRow = fontSizeOptionsDataSource.firstIndex(of: Storage.appFontSize) {
            fontSizePickerView.selectRow(selectedRow, inComponent: 0, animated: false)
        }
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

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        profileImageView.setRoundShape()
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
                                              font: UIFont.appFont(name: Constants.Font.LatoRegular, size: 14))
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
    
    private func configurePickerTextField(_ textField: UITextField, inputView: UIView) {
        textField.inputView = inputView
        textField.inputAccessoryView = pickerToolbar()
        textField.tintColor = .clear
        textField.inputAssistantItem.leadingBarButtonGroups = []
        textField.inputAssistantItem.trailingBarButtonGroups = []
    }
    
    private func pickerToolbar() -> UIToolbar {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(dismissPicker))
        ]
        return toolbar
    }
    
    @objc private func dismissPicker() {
        view.endEditing(true)
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

    /// Wrap the storyboard's root view in a UIScrollView so the Settings
    /// screen can scroll vertically when the content (font-size rows, exam
    /// location picker, face-id row, etc.) exceeds the screen height.
    ///
    /// Pre-flight check: the storyboard's root view is referenced via
    /// `view!` here. We capture its CURRENT frame (already set by UIKit
    /// to the device's actual screen dimensions — not the storyboard's
    /// 414×896 design rect) and use those to size the new `rootView` we
    /// swap in.
    ///
    /// Original bug: this method used `UIView(frame: storyboardView.frame)`
    /// which at design-time is 414×896. The storyboard's root view's frame
    /// at runtime IS 414×896 too (UIKit reads `<rect>` from the storyboard
    /// XML verbatim), so on any device whose width was less than 414 the
    /// contents were vertically and horizontally anchored to a 414-pixel
    /// container sitting inside a 390-pixel window — left-bleeding off
    /// the screen with the avatar's centerX anchored to the wrong center.
    ///
    /// Fix: use `CGRect.zero` for the rootView frame and pin rootView to
    /// its parent's edges via Auto Layout. This way the layout tracks the
    /// actual screen size on every device.
    private func configureScrollableLayout() {
        let storyboardView = view!
        let designHeight = max(storyboardView.bounds.height, 896)

        let rootView = UIView(frame: .zero)
        rootView.backgroundColor = storyboardView.backgroundColor
        rootView.translatesAutoresizingMaskIntoConstraints = false

        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .interactive
        scrollView.backgroundColor = storyboardView.backgroundColor
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        storyboardView.translatesAutoresizingMaskIntoConstraints = false
        self.view = rootView
        rootView.addSubview(scrollView)
        scrollView.addSubview(storyboardView)

        // NB: do NOT install rootView-to-parent constraints here.
        //
        // After `self.view = rootView`, UIKit may not have inserted
        // rootView into its superview synchronously — calling
        // `rootView.superview` immediately often returns nil. Pinning
        // rootView to `parent.topAnchor` here also breaks the parent's
        // own auto-layout (the previous code path set
        // `parent.translatesAutoresizingMaskIntoConstraints = false`,
        // which is unsafe to do from a child view controller).
        //
        // Instead, install the rootView-to-superview pinning in
        // `installRootViewConstraintsIfNeeded()` (called from
        // `viewWillLayoutSubviews`), where superview is guaranteed to be
        // set AND we never touch the parent's translatesAutoresizingMaskIntoConstraints.
        rootViewConstraints = []

        // These constraints don't depend on `rootView.superview`, so they
        // can still be installed eagerly.
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: rootView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),

            storyboardView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            storyboardView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            storyboardView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            storyboardView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            storyboardView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            storyboardView.heightAnchor.constraint(greaterThanOrEqualToConstant: designHeight)
        ])
    }

    /// Install rootView → superview constraints once superview is
    /// guaranteed to be non-nil. Uses the parent's `safeAreaLayoutGuide`
    /// so the scrollable content respects the tab bar / status bar /
    /// home-indicator insets — pinning to the raw edges previously made
    /// the last rows sit underneath the tab bar.
    private func installRootViewConstraintsIfNeeded() {
        guard rootViewConstraints.isEmpty,
              let parent = view?.superview else {
            return
        }
        // Install rootView pinned to parent's safe area so content
        // never bleeds behind the tab bar / home indicator.
        let guide = parent.safeAreaLayoutGuide
        let cs = [
            view!.topAnchor.constraint(equalTo: guide.topAnchor),
            view!.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            view!.trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            view!.bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        ]
        NSLayoutConstraint.activate(cs)
        rootViewConstraints = cs
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        installRootViewConstraintsIfNeeded()
    }
    
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
                self?.countContainerView.isHidden = !(IsEnableLogin ? profileInfo.isEmailZoom : false)
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
         Observable
            .just(fontSizeOptionsDataSource)
            .bind(to: fontSizePickerView.rx.itemTitles) { _, item in
                item.title
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
         soundEffectsSwitch
            .rx
            .isOn
            .skip(1)
            .subscribe(onNext: { isEnabled in
                Storage.isButtonSoundEnabled = isEnabled
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
            }),
         fontSizePickerView
            .rx
            .modelSelected(AppFontSize.self)
            .compactMap { $0.first }
            .subscribe(onNext: { [weak self] fontSize in
                self?.applyFontSize(fontSize)
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func applyFontSize(_ fontSize: AppFontSize) {
        fontSizeTextfield.text = fontSize.title
        fontSizeTextfield.applyAppFontScaling()
        guard Storage.appFontSize != fontSize else {
            return
        }
        Storage.appFontSize = fontSize
        setupSwiftDrawer()
        NotificationCenter.default.post(name: .AppFontSizeDidChange, object: nil)
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
