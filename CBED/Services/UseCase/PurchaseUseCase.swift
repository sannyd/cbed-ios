//
//  PurchaseUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 30/07/2021.
//

import Foundation
import RxSwift

protocol PurchaseAPIUseCase {
    func purchaseMembership(request: PurchaseMembershipRequestM) -> Single<Any>
}

extension PurchaseAPIUseCase {
    func purchaseMembership(request: PurchaseMembershipRequestM) -> Single<Any> {
        guard let params = request.toParams() else {
            return .error(CustomError.CannotGetParams)
        }
        
        return APIClient
            .shared
            .request(PurchaseRouter.purchaseMembership(params: params))
            .map { _ in }
    }
}
