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
        let inAppPurchaseItemTrigger: Observable<InAppPurchaseM>
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
        
        return Output(data: data)
    }
}
