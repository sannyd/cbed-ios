//
//  UpdateProfileViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 8/29/21.
//

import UIKit
import RxSwift
import RxCocoa

final class UpdateProfileViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameTextfield: UITextField!
    @IBOutlet weak var stateTextfield: UITextField!
    @IBOutlet weak var phoneTextfield: PhoneTextfield!
    @IBOutlet weak var buttonBack: UIButton!
    
    @IBOutlet weak var buttonUpdate: CustomBorderButton!
    /// V11.3 — displays "User ID: <id>" under the phone-number row.
    /// Bound to `labelUserId` in Setting.storyboard.
    @IBOutlet weak var labelUserId: UILabel!
    // MARK: - Properties
    
    var viewModel: UpdateProfileViewModel!
    var disposeBag = DisposeBag()
    
    private let statePicker = UIPickerView()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        profileImageView.setRoundShape()
        stateTextfield.inputView = statePicker
        nameTextfield.text = Storage.profileInfo?.name
        stateTextfield.text = Storage.profileInfo?.state
        phoneTextfield.text = Storage.profileInfo?.phone
        configureUserIdLabel()
        bindViewModel()
    }

    /// V11.3 — renders the signed-in user's account id, e.g. "User ID: 2815".
    ///
    /// The id comes from `Storage.profileInfo?.id`, which is the `id` field
    /// decoded from the `/api/users/me` payload. It is the same value the
    /// app sends to Firebase Analytics via `Analytics.setUserID(String(uid))`
    /// in `AppViewModel`, so the number shown here is the one that shows up
    /// in GA4 — which is the point: it lets a user quote their id and have
    /// support tie the session to a specific account.
    ///
    /// Shows "User ID: N/A" when the profile has not loaded yet (logged
    /// out, or the fetch failed) rather than an empty row.
    private func configureUserIdLabel() {
        guard let userId = Storage.profileInfo?.id else {
            labelUserId.text = "User ID: N/A"
            return
        }
        labelUserId.text = "User ID: \(userId)"
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let profileImageTrigger = profileImageView
            .rxGestureTapped
            .flatMap { _ -> Observable<Int> in
                return self.showAlert(title: "", message: "Choose or take an image", style: .actionSheet, actions: [
                    .init(title: "Camera", style: .default),
                    .init(title: "Gallery", style: .default),
                    .init(title: "Cancel", style: .cancel)
                ])
            }
        
        let state = statePicker
            .rx
            .modelSelected(String.self)
            .map { $0.first ?? "" }
            .do(onNext: { [weak self] text in
                self?.stateTextfield.text = text
            })
            .asObservable()
        
        let input = UpdateProfileViewModel.Input(profileImageTrigger: profileImageTrigger,
                                                 name: nameTextfield.rx.text.orEmpty.asObservable(),
                                                 state: state,
                                                 phone: phoneTextfield.rx.text.map { _ in self.phoneTextfield.text ?? "" }.asObservable(),
                                                 buttonUpdateTrigger: buttonUpdate.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .isButtonUpdateValid
            .asDriver(onErrorJustReturn: false)
            .drive(buttonUpdate.rx.isEnabled),
         output
            .profileImage
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] image in
                if image ==  nil {
                    self?.profileImageView.image = #imageLiteral(resourceName: "img_user_placeholder")
                } else {
                    self?.profileImageView.image = image
                }
            }),
         output
            .states
            .asDriverOnErrorJustComplete()
            .drive(statePicker.rx.itemTitles){ _, item in
                return "\(item)"
            },
         output
            .isLoading
            .asDriver(onErrorJustReturn: false)
            .drive(LoadingIndicatorView.rx.isAnimating),
         output
            .error
            .asDriverOnErrorJustComplete()
            .drive(errorBinding),
         buttonBack
            .rxButtonTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
}
