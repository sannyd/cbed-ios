//
//  SettingViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension SettingViewModel {
    struct Input {
        let viewWillAppear: Observable<Void>
        let buttonRestorePurchaseTrigger: Observable<Void>
        let buttonEditTrigger: Observable<Void>
        let buttonDeactivateTrigger: Observable<Void>
    }
    
    struct Output {
        let profileInfo: Observable<ProfileInfoM>
        let restorePurchaseSuccess: Observable<Void>
        let deactivateSuccess: Observable<Any>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct SettingViewModel: ViewModel {
    let useCase: SettingUseCaseType
    let navigator: SettingNavigatorType
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let userProfile = input
            .viewWillAppear
            .map { _ in Storage.profileInfo }
        
        let restorePurchaseSuccess = input
            .buttonRestorePurchaseTrigger
            .flatMapLatest { _ in
                return self.verifyIAPLocally()
                    .trackError(errorTracker)
                    .catch { _ in
                        return .error(CustomError.CannotRestoreIAP)
                    }
            }
            .flatMapLatest { _ in
                return self.getProfile()
            }
            .do(onNext: { profile in
                Storage.profileInfo = profile
                NotificationCenter.default.post(.init(name: .PurchaseSuccessful))
            })
            .mapToVoid()
            .do(onNext: navigator.presentRestorePurchaseSuccessAlert)
        
        input
            .buttonEditTrigger
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.presentUpdateProfileVC)
            .disposed(by: disposeBag)
                
                let deactivateSuccess = input
                .buttonDeactivateTrigger
                .flatMapLatest { _ in
                    return self.deactivate()
                }
                
        
        return Output(profileInfo: userProfile.unwrap(),
                      restorePurchaseSuccess: restorePurchaseSuccess.asObservable(),
                      deactivateSuccess: deactivateSuccess.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    private func verifyIAPLocally() -> Observable<Void> {
        Observable.create { observer in
            StoreKitService.shared.getLastReceipt { receipt in
                if let receipt = receipt {
                    StoreKitService.shared.verifyReceipt(receipt, completion: { isPurchased, monthType in
                        CurrentMembershipType = monthType
                        observer.onNext(())
                    })
                } else {
                    observer.onError(CustomError.CannotRestoreIAP)
                }
            }
            
            return Disposables.create()
        }
    }
    
    private func getProfile() -> Observable<ProfileInfoM> {
        return useCase
            .getProfileInfo()
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
    
    private func deactivate() -> Observable<Any> {
        return useCase
            .deactivate()
            .asObservable()
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
