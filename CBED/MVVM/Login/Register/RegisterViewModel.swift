//
//  RegisterViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 10/07/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension RegisterViewModel {
    struct Input {
        let profileImageTrigger: Observable<Int>
        let name: Observable<String>
        let email: Observable<String>
        let password: Observable<String>
        let state: Observable<String>
        let buttonRegisterTrigger: Observable<Void>
    }
    
    struct Output {
        let isButtonRegisterValid: Observable<Bool>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct RegisterViewModel: ViewModel {
    let useCase: RegisterUseCaseType
    let navigator: RegisterNavigatorType
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let profileImage = input
            .profileImageTrigger
            .flatMap { index -> Observable<[UIImagePickerController.InfoKey: Any]> in
                return navigator.showImagePicker(index: index)
            }
            .map { (info: [UIImagePickerController.InfoKey : Any]) -> UIImage? in
                if let originalImage = info[.originalImage] as? UIImage {
                    return originalImage
                }
                if let editImage = info[.editedImage] as? UIImage {
                    return editImage
                }
                return nil
            }
        
        let sharedData = Observable.combineLatest(profileImage,
                                                  input.name,
                                                  input.email,
                                                  input.password,
                                                  input.state)
        
        let isButtonRegisterValid = sharedData
            .map { profileImage, name, email, password, state in
                return profileImage != nil &&
                    !name.isEmpty &&
                    !email.isEmpty &&
                    !password.isEmpty &&
                    !state.isEmpty
            }
        
        input
            .buttonRegisterTrigger
            .withLatestFrom(sharedData)
            .map { profileImage, name, email, password, state in
                return (RegisterRequestM(name: name, email: email, password: password, state: state), profileImage)
            }
            .flatMapLatest(register(request:image:))
            .mapToVoid()
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.showRegisterSuccessAlert)
            .disposed(by: disposeBag)
        
        return Output(isButtonRegisterValid: isButtonRegisterValid,
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    private func register(request: RegisterRequestM, image: UIImage?) -> Observable<RegisterResponseM> {
        self.useCase
            .register(request: request,
                      imageData: image?.jpegData(compressionQuality: 0.8))
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
