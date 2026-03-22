//
//  InAppPurchaseUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 07/07/2021.
//

import RxSwift

protocol InAppPurchaseUseCaseType {
    func purchaseMembership(request: PurchaseMembershipRequestM) -> Single<Any>
    func getSubscriptionPlan() -> Single<[SubscriptionPlanM]>
    func getProfileInfo() -> Single<ProfileInfoM>
}

struct InAppPurchaseUseCase: InAppPurchaseUseCaseType,
                             PurchaseAPIUseCase,
                             ProfileUseCase {
    
}
