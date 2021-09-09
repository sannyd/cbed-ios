//
//  UpdateProfileViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 8/29/21.
//

import RxSwift
import RxCocoa
import RxNuke
import Nuke
import PhoneNumberKit

// MARK: Input + Output
extension UpdateProfileViewModel {
    struct Input {
        let profileImageTrigger: Observable<Int>
        let name: Observable<String>
        let state: Observable<String>
        let phone: Observable<String>
        let buttonUpdateTrigger: Observable<Void>
    }
    
    struct Output {
        let isButtonUpdateValid: Observable<Bool>
        let profileImage: Observable<UIImage?>
        let states: Observable<[String]>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct UpdateProfileViewModel: ViewModel {
    let useCase: UpdateProfileUseCaseType
    let navigator: UpdateProfileNavigatorType
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let profileImageStorage = BehaviorRelay<UIImage?>(value: nil)
        
        input
            .profileImageTrigger
            .filter {
                $0 != 2
            }
            .flatMapLatest { index -> Observable<[UIImagePickerController.InfoKey: Any]> in
                return navigator
                    .showImagePicker(index: index)
            }
            .map { (info: [UIImagePickerController.InfoKey : Any]) -> UIImage? in
                if let editImage = info[.editedImage] as? UIImage {
                    return editImage
                }
                
                if let originalImage = info[.originalImage] as? UIImage {
                    return originalImage
                }
                
                return nil
            }
            .bind(to: profileImageStorage)
            .disposed(by: disposeBag)
        
        Observable.just(Storage.profileInfo?.avatar)
            .unwrap()
            .map { URL(string: $0) }
            .unwrap()
            .flatMapLatest { ImagePipeline.shared.rx.loadImage(with: $0) }
            .map { $0.image }
            .subscribe(onNext: { image in
                profileImageStorage.accept(image)
            }, onError: { error in
                Log.e(error)
            })
            .disposed(by: disposeBag)
        
        let sharedData = Observable.combineLatest(profileImageStorage,
                                                  input.name.startWith(Storage.profileInfo?.name ?? ""),
                                                  input.state.startWith(Storage.profileInfo?.state ?? ""),
                                                  input.phone.startWith(""))
        
        let isButtonUpdateValid = sharedData
            .map { profileImage, name, state, phone in
                return profileImage != nil &&
                    !name.isEmpty &&
                    !state.isEmpty &&
                    !phone.isEmpty
            }
        
        input
            .buttonUpdateTrigger
            .withLatestFrom(sharedData)
            .map { profileImage, name, state, phone in
                var formattedPhone = phone
                
                let phoneNumberKit = PhoneNumberKit()
                if let phoneNumber = try? phoneNumberKit.parse(phone) {
                    formattedPhone = phoneNumberKit.format(phoneNumber, toType: .international)
                }
                
                return (UpdateProfileRequestM(name: name, state: state, phone: formattedPhone), profileImage)
            }
            .flatMapLatest(updateProfileInfo(request:image:))
            .do(onNext: { updatedProfile in
                Storage.profileInfo = updatedProfile
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.showUpdateProfileSuccessAlert)
            .disposed(by: disposeBag)
        
        return Output(isButtonUpdateValid: isButtonUpdateValid.startWith(false),
                      profileImage: profileImageStorage.asObservable(),
                      states: .just(Constants.states),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    private func updateProfileInfo(request: UpdateProfileRequestM, image: UIImage?) -> Observable<ProfileInfoM> {
        self.useCase
            .updateProfileInfo(request: request,
                               imageData: image?.jpegData(compressionQuality: 0.8))
            .trackActivity(activityIndicator)
            .trackError(errorTracker)
            .catch { _ in
                return .never()
            }
    }
}
