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
    }
    
    struct Output {
        let profileInfo: Observable<ProfileInfoM>
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
        
        input
            .buttonRestorePurchaseTrigger
            .flatMapLatest { _ in
                return self.verifyIAPLocally()
                    .catch { _ in
                        return .never()
                    }
            }
            .flatMapLatest { _ in
                return self.getProfile()
            }
            .do(onNext: { profile in
                Storage.profileInfo = profile
            })
            .mapToVoid()
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.presentRestorePurchaseSuccessAlert)
            .disposed(by: disposeBag)
        
        input
            .buttonEditTrigger
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.presentUpdateProfileVC)
            .disposed(by: disposeBag)
        
        return Output(profileInfo: userProfile.unwrap(),
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
                    observer.onNext(())
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
}
