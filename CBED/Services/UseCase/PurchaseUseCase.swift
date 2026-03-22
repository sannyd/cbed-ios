import Foundation
import RxSwift

protocol PurchaseAPIUseCase {
    func purchaseMembership(request: PurchaseMembershipRequestM) -> Single<Any>
    func getSubscriptionPlan() -> Single<[SubscriptionPlanM]>
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
    
    func getSubscriptionPlan() -> Single<[SubscriptionPlanM]> {
        return APIClient
            .shared
            .requestWithoutValidation(PurchaseRouter.getSubscriptionPlans)
    }
}
