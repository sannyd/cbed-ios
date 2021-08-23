//
//  InAppPurchaseViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 07/07/2021.
//

import RxSwift
import RxCocoa
import SwiftyStoreKit

// MARK: Input + Output
extension InAppPurchaseViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let inAppPurchaseItemTrigger: Observable<InAppPurchaseType>
    }
    
    struct Output {
        let data: Observable<[CommonCollectionViewSection<InAppPurchaseType>]>
        let purchaseSuccessInvoked: Observable<Void>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct InAppPurchaseViewModel: ViewModel {
    let useCase: InAppPurchaseUseCaseType
    let navigator: InAppPurchaseNavigatorType
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
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
            .flatMapLatest(handleIAP(purchaseID:))
            .flatMapLatest(verifyIAP(purchaseDetails:))
            .do(onNext: { profile in
                NotificationCenter.default.post(.init(name: .PurchaseSuccessful))
            })
            .flatMapLatest(getProfile)
            .do(onNext: { profile in
                Storage.profileInfo = profile
            })
            .map { _ in }
        
        return Output(data: data,
                      purchaseSuccessInvoked: purchaseSuccessInvoked.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    private func handleIAP(purchaseID: String) -> Single<PurchaseDetails> {
        Single<PurchaseDetails>.create { observer in
            SwiftyStoreKit.purchaseProduct(purchaseID, quantity: 1, atomically: true) { result in
                switch result {
                case .success(let product):
                    Log.d(product)
                    // fetch content from your server, then:
                    observer(.success(product))
                    
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
                    
                    observer(.failure(error))
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
                    // Read receiptData
                    return useCase
                        .purchaseMembership(request: PurchaseMembershipRequestM(receiptData: receiptString))
                        .trackError(errorTracker)
                        .trackActivity(activityIndicator)
                        .catch { _ in
                            return .never()
                        }
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
                        observer.onCompleted()
                    })
                } else {
                    observer.onNext(())
                    observer.onCompleted()
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
