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
    }
}

struct InAppPurchaseViewModel: ViewModel {
    let useCase: InAppPurchaseUseCaseType
    let navigator: InAppPurchaseNavigatorType
    
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
        
        navigator
            .alertViewPublisher
            .map { events -> InAppPurchaseMonth? in
                switch events {
                case .didTapProceed(let month):
                    return month
                }
            }
            .unwrap()
            .map { $0.purchaseID }
            .subscribe(onNext: { purchaseID in
                SwiftyStoreKit.purchaseProduct(purchaseID, quantity: 1, atomically: false) { result in
                    switch result {
                    case .success(let product):
                        Log.d(product)
                        // fetch content from your server, then:
                        
                        if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
                            FileManager.default.fileExists(atPath: appStoreReceiptURL.path) {

                            do {
                                let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .dataReadingMapped)
                                print(receiptData)
                                let string = String(data: receiptData, encoding: .utf8)
                                Log.d(string)
                                
                                let receiptString = receiptData.base64EncodedString(options: [])
                                Log.d(receiptString)
                                // Read receiptData
                            }
                            catch { print("Couldn't read receipt data with error: " + error.localizedDescription) }
                        }
                        
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
                    }
                }
            })
            .disposed(by: disposeBag)
        
        return Output(data: data)
    }
}
