//
//  StoreKitService.swift
//  CBED
//
//  Created by Jimmy Hoang on 8/22/21.
//

import Foundation
import SwiftyStoreKit
import StoreKit

class StoreKitService {
    // Singleton
    static let shared = StoreKitService()

    var localMemberPlan: InAppPurchaseMonth?

    func getLastReceipt(completion: @escaping (ReceiptInfo?) -> Void)  {
        let validator = AppleReceiptValidator(service: .production)
        
        SwiftyStoreKit.verifyReceipt(using: validator) { result in
            switch result {
            case .success(let receipt):
                let decoder = JSONDecoder()
                //                if let data = try? JSONSerialization.data(withJSONObject: receipt, options: .prettyPrinted),
                //                   let receiptInfo = try? decoder.decode(ReceiptM.self, from: data),
                //                   let lastInApp = receiptInfo.receipt?.inApp?.last {
                ////                    completion(lastInApp)
                //                    completion(receipt)
                //                }
                completion(receipt)
            case .error(error: let error):
                print("nani: \(error)")
                completion(nil)
            }
        }
    }
    
    func verifyReceipt(_ receipt: ReceiptInfo, completion: @escaping (Bool, InAppPurchaseMonth?) -> Void) {
        let array = InAppPurchaseMonth.allCases.map { $0.purchaseID }
        let setProductionIds = Set(array)
        let result = SwiftyStoreKit.verifySubscriptions(ofType: .nonRenewing(validDuration: 3600 * 24 * 365),
                                                        productIds: setProductionIds,
                                                        inReceipt: receipt)
        
        switch result {
        case .purchased(let expiryDate, let items):
            print("nani: \(expiryDate) - items: \(items)")
            var temp = items
            temp = temp.sorted(by: { $0.originalPurchaseDate < $1.originalPurchaseDate })
            if let purchaseID = temp.last?.productId,
               let monthType = InAppPurchaseMonth(rawValue: purchaseID) {
                completion(true, monthType)
            } else {
                completion(false, nil)
            }
        case .expired(let expiryDate, let items):
            print("nani: \(expiryDate) - items: \(items)")
            completion(false, nil)
        case .notPurchased:
            completion(false, nil)
        }
    }
    
    func previouslyPurchaseItems(_ receipt: ReceiptInfo, completion: @escaping ([InAppPurchaseMonth]) -> Void) {
        let array = InAppPurchaseMonth.allCases.map { $0.purchaseID }
        let setProductionIds = Set(array)
        let result = SwiftyStoreKit.verifySubscriptions(ofType: .nonRenewing(validDuration: 3600 * 24 * 365),
                                                        productIds: setProductionIds,
                                                        inReceipt: receipt)
        
        switch result {
        case .purchased(let expiryDate, let items):
            print("nani: \(expiryDate) - items: \(items)")
            var temp = items
            temp = temp.sorted(by: { $0.originalPurchaseDate < $1.originalPurchaseDate })
            
            var purchasedMonths: Set<InAppPurchaseMonth> = []
            
            for item in temp {
                if let monthType = InAppPurchaseMonth(rawValue: item.productId) {
                    purchasedMonths.insert(monthType)
                }
            }
            
            completion(Array(purchasedMonths))
        case .expired(let expiryDate, let items):
            print("nani: \(expiryDate) - items: \(items)")
            completion([])
        case .notPurchased:
            completion([])
        }
    }
}
