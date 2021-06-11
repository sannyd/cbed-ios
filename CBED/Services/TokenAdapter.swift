//
//  TokenAdapter.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 3/12/21.
//

import Alamofire
import RxSwift

final class JWTAccessTokenAdapter: RequestInterceptor {
    typealias JWT = String
    private let accessToken: JWT
    let disposeBag = DisposeBag()

    init(accessToken: JWT) {
        self.accessToken = accessToken
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Swift.Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        urlRequest.setValue("Bearer " + Storage.accessToken!, forHTTPHeaderField: "Authorization")
        
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetryWithError(error))
        }
        
//        getNewAccessToken()
//            .subscribe(onSuccess: { response in
//                Storage.accessToken = response.access
////                Storage.refreshToken = response.refresh
//                completion(.retry)
//            }, onFailure: { error in
//                completion(.doNotRetryWithError(error))
//            })
//            .disposed(by: disposeBag)
    }
    
//    func getNewAccessToken() -> Single<RefreshTokenResponseM> {
//        guard let refreshToken = Storage.refreshToken else {
//            return .never()
//        }
//        return APIClient
//            .shared
//            .request(TokenRouter.refresh(params: ["refresh": refreshToken]))
//            .catch { error in
//                return .error(error)
//            }
//    }
}
