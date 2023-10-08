//
//  InAppPurchaseViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 07/07/2021.
//

import RxSwift
import RxCocoa
import SwiftyStoreKit
import WidgetKit

extension ObservableType {
    func filterErrors() -> Observable<Element> {
        return materialize()
            .filter { item in
                item.element != nil
            }
            .dematerialize()
    }
}

// MARK: Input + Output
extension InAppPurchaseViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let inAppPurchaseItemTrigger: Observable<InAppPurchaseType>
        let buttonRestorePurchaseTrigger: Observable<Void>
    }
    
    struct Output {
        let data: Observable<[CommonCollectionViewSection<InAppPurchaseType>]>
        let purchaseSuccessInvoked: Observable<Void>
        let isShowingIAPBlockerView: Observable<(Bool, Bool)>
        let previouslyPurchasedInvoked: Observable<Void>
        let restorePurchaseSuccess: Observable<Void>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct InAppPurchaseViewModel: ViewModel {
    let useCase: InAppPurchaseUseCaseType
    let navigator: InAppPurchaseNavigatorType
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    let isShowingIAPBlockerView = BehaviorRelay<(Bool, Bool)>(value: (false, false))
    let previouslyPurchasedTrigger = PublishRelay<Void>()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        
        
        let data = input
            .firstLoadTrigger
            .map { _ in
                return [CommonCollectionViewSection(items: [InAppPurchaseType.ProBar,
                                                            InAppPurchaseType.BabyBar])]
            }
        input
            .inAppPurchaseItemTrigger
            .map { $0.months }
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.showMonthAlertView(leftData:rightData:))
            .disposed(by: disposeBag)
        
        let purchaseSuccessInvoked = navigator
            .alertViewPublisher
            .map { events -> InAppPurchaseMonth? in
                switch events {
                case .didTapProceed(let month):
                    return month
                }
            }
            .unwrap()
            .map { $0.purchaseID }
            .do(onNext: { _ in
                isShowingIAPBlockerView.accept((true, false))
            })
//            .flatMapLatest{ purchaseID -> Observable<(String, Bool)> in
//                let remoteConfigData = remoteConfig.configValue(forKey: "remote_configs").dataValue
//
//                if let remoteConfigs = try? JSONSerialization.jsonObject(with: remoteConfigData,
//                                                                            options: .mutableContainers) as? [String: Any],
//                      let isEnableLogin = remoteConfigs["is_enable_login"] as? Bool,
//                      !isEnableLogin {
//                    return previouslyPurchasedItems(purchaseID: purchaseID)
//                        .do(onNext: { purchaseID, isContinue in
//                            if !isContinue {
//                                navigator.presentRestorePurchaseSuccessAlert()
//                            }
//                        })
//                        .catch { _ in
//                            self.isShowingIAPBlockerView.accept(false)
//                            return .never()
//                        }
//                } else {
//                    return .just((purchaseID, true))
//                }
//            }
//            .flatMapLatest{ purchaseID, isContinue in
//                return handleIAP(purchaseID: purchaseID, isContinue: isContinue)
//                    .catch { _ in
//                        self.isShowingIAPBlockerView.accept(false)
//                        return .never()
//                    }
//            }
            .flatMapLatest{ purchaseID in
                return handleIAP(purchaseID: purchaseID)
                    .catch { _ in
                        self.isShowingIAPBlockerView.accept((false, false))
                        return .never()
                    }
            }
            .flatMapLatest{ purchaseDetails in
                return verifyIAP(purchaseDetails: purchaseDetails)
                    .catch { _ in
                        self.isShowingIAPBlockerView.accept((false, false))
                        return .never()
                    }
            }
            .flatMapLatest { _ in
                return getProfile()
                    .catch { _ in
                        self.isShowingIAPBlockerView.accept((false, false))
                        return .never()
                    }
            }
            .do(onNext: { profile in
                Storage.profileInfo = profile
                Storage.currentLevel = profile.lastSectionName
                WidgetCenter.shared.reloadAllTimelines()
                NotificationCenter.default.post(.init(name: .PurchaseSuccessful))
                isShowingIAPBlockerView.accept((false, false))
            })
//            , onError: { error in
//                isShowingIAPBlockerView.accept(false)
//            }, onCompleted: {
//                isShowingIAPBlockerView.accept(false)
//            })
            .map { _ in }
        
        let restorePurchaseSuccess = input
            .buttonRestorePurchaseTrigger
            .do(onNext: { _ in
                isShowingIAPBlockerView.accept((true, true))
            })
            .flatMapLatest { _ in
                return self.verifyIAPLocally()
                    .trackError(errorTracker)
                    .catch { _ in
                        isShowingIAPBlockerView.accept((false, false))
                        return .never()
                    }
            }
            .flatMapLatest { _ in
                return self.getProfile()
            }
            .do(onNext: { profile in
                Storage.profileInfo = profile
                Storage.currentLevel = profile.lastSectionName
                WidgetCenter.shared.reloadAllTimelines()
            })
            .mapToVoid()
            .do(onNext: navigator.presentRestorePurchaseSuccessAlert)
        
        return Output(data: data,
                      purchaseSuccessInvoked: purchaseSuccessInvoked.asObservable(),
                      isShowingIAPBlockerView: isShowingIAPBlockerView.asObservable(),
                      previouslyPurchasedInvoked: previouslyPurchasedTrigger.asObservable(),
                      restorePurchaseSuccess: restorePurchaseSuccess.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
//    private func handleIAP(purchaseID: String, isContinue: Bool = true) -> Observable<PurchaseDetails> {
//        Observable<PurchaseDetails>.create { observer in
//            if isContinue {
//                SwiftyStoreKit.purchaseProduct(purchaseID, quantity: 1, atomically: true) { result in
//                    switch result {
//                    case .success(let product):
//                        Log.d(product)
//                        // fetch content from your server, then:
//    //                    observer(.success(product))
//                        observer.onNext(product)
//                        if product.needsFinishTransaction {
//                            SwiftyStoreKit.finishTransaction(product.transaction)
//                        }
//                        print("Purchase Success: \(product.productId)")
//                    case .error(let error):
//                        switch error.code {
//                        case .unknown: print("Unknown error. Please contact support")
//                        case .clientInvalid: print("Not allowed to make the payment")
//                        case .paymentCancelled: break
//                        case .paymentInvalid: print("The purchase identifier was invalid")
//                        case .paymentNotAllowed: print("The device is not allowed to make the payment")
//                        case .storeProductNotAvailable: print("The product is not available in the current storefront")
//                        case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
//                        case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
//                        case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
//                        default: print((error as NSError).localizedDescription)
//                        }
//                        observer.onError(error)
//    //                    observer(.failure(error))
//                    }
//                }
//            } else {
//                CurrentMembershipType = InAppPurchaseMonth(rawValue: purchaseID)
//                previouslyPurchasedTrigger.accept(())
//                observer.onCompleted()
//            }
//
//
//            return Disposables.create()
//        }
//    }
    
    private func handleIAP(purchaseID: String) -> Observable<PurchaseDetails> {
        Observable<PurchaseDetails>.create { observer in
            SwiftyStoreKit.purchaseProduct(purchaseID, quantity: 1, atomically: true) { result in
                switch result {
                case .success(let product):
                    Log.d(product)
                    // fetch content from your server, then:
                    observer.onNext(product)
                    if product.needsFinishTransaction {
                        SwiftyStoreKit.finishTransaction(product.transaction)
                    }
                    print("Purchase Success: \(product.productId)")
                case .error(let error):
                    switch error.code {
                    case .unknown: print("Unknown error. Please contact support")
                    case .clientInvalid: print("Not allowed to make the payment")
                    case .paymentCancelled: break
                    case .paymentInvalid: print("The purchase identifier was invalid")
                    case .paymentNotAllowed: print("The device is not allowed to make the payment")
                    case .storeProductNotAvailable: print("The product is not available in the current storefront")
                    case .cloudServicePermissionDenied: print("Access to cloud service information is not allowed")
                    case .cloudServiceNetworkConnectionFailed: print("Could not connect to the network")
                    case .cloudServiceRevoked: print("User has revoked permission to use this cloud service")
                    default: print((error as NSError).localizedDescription)
                    }
                    observer.onError(error)
                }
            }
            return Disposables.create()
        }
    }
    
    private func verifyIAP(purchaseDetails: PurchaseDetails) -> Observable<Void> {
        let remoteConfigData = remoteConfig.configValue(forKey: "remote_configs").dataValue
    
        if let remoteConfigs = try? JSONSerialization.jsonObject(with: remoteConfigData,
                                                                    options: .mutableContainers) as? [String: Any],
              let isEnableLogin = remoteConfigs["is_enable_login"] as? Bool,
              !isEnableLogin {
            
            return verifyIAPLocally()
        } else {
            if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {

                do {
                    let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .dataReadingMapped)
                    let receiptString = receiptData.base64EncodedString(options: [])
                    Log.d("receiptString: \(receiptString)")
                    
                    // Read receiptData
                    return useCase
                        .purchaseMembership(request: PurchaseMembershipRequestM(receiptData: receiptString))
                        .trackError(errorTracker)
                        .trackActivity(activityIndicator)
                        .map { _ in }
                } catch {
                    Log.e("Couldn't read receipt data with error: " + error.localizedDescription)
                    return Observable.error(error)
                }
            } else {
                return .error(CustomError.CannotGetIAPReceiptData)
            }
        }
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
    
    private func previouslyPurchasedItems(purchaseID: String) -> Observable<(String, Bool)> {
        Observable.create { observer in
            StoreKitService.shared.getLastReceipt { receipt in
                if let receipt = receipt {
                    StoreKitService.shared.previouslyPurchaseItems(receipt, completion: { purchasedMonths in
                        let purchasedMonthIDs = purchasedMonths.map { $0.purchaseID }
                        if purchasedMonthIDs.contains(purchaseID) {
                            observer.onNext((purchaseID, false))
                        } else {
                            observer.onNext((purchaseID, true))
                        }
                        
                    })
                } else {
                    observer.onNext((purchaseID, true))
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
