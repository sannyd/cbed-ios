//
//  TokenAdapter.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 3/12/21.
//

import Alamofire
import RxSwift

var isRefreshing: Bool = false

final class JWTAccessTokenAdapter: RequestInterceptor {
    typealias JWT = String
    private let retryLimit = 3
    let disposeBag = DisposeBag()
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Swift.Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        if !(urlRequest.url?.absoluteString.contains("auth") ?? false) {
            if let accessToken = Storage.accessToken {
                urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
            } else {
                completion(.failure(NSError(domain: "401", code: 401, userInfo: [:])))
            }
        }
        
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 || response.statusCode == 403  else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetry)
        }
        
        guard !(request.task?.response?.url?.absoluteString.contains("/auth/token-refresh") ?? true) else {
            DispatchQueue.main.async {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.logout()
            }
          
            return completion(.doNotRetry)
        }
//        Log.networkErrors(error)
        
        guard Storage.refreshToken != nil else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        refreshToken { isSuccess in
            if isSuccess {
                completion(.retry)
            } else {
                DispatchQueue.main.async {
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.logout()
                }
                completion(.doNotRetryWithError(error))
            }
        }
        
//        getNewAccessToken()
//            .subscribe(onSuccess: { response in
//                Storage.accessToken = response.access
//                completion(.retry)
//            }, onFailure: { error in
//                let appDelegate = UIApplication.shared.delegate as! AppDelegate
//                appDelegate.logout()
//                completion(.doNotRetryWithError(error))
//            })
//            .disposed(by: disposeBag)
    }
    
    func getNewAccessToken() -> Single<TokenRefreshResponseM> {
        guard let refreshToken = Storage.refreshToken, !isRefreshing else {
            DispatchQueue.main.async {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                appDelegate.logout()
            }
            return .never()
        }
        isRefreshing = true
        return APIClient
            .shared
            .requestWithoutValidation(AuthRouter.refreshToken(params: ["refresh": refreshToken]))
            .catch { error in
                return .error(error)
            }
    }
    
    func refreshToken(completion: @escaping (_ isSuccess: Bool) -> Void) {
        guard let refreshToken = Storage.refreshToken, !isRefreshing else {
            return
        }
        isRefreshing = true
        let parameters = ["refresh": refreshToken]
        AF.request("https://cbed.airdemo.xyz/api/auth/token-refresh/", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON { response in
            Log.d(response)
            if let error = response.error {
                Log.e(error)
                isRefreshing = false
                completion(false)
            }
            
            if let data = response.data, let token = (try? JSONSerialization.jsonObject(with: data, options: [])
                as? [String: Any])?["access"] as? String {
                isRefreshing = false
                Storage.accessToken = token
                print("\nRefresh token completed successfully. New token is: \(token)\n")
                completion(true)
            } else {
                isRefreshing = false
                completion(false)
            }
        }
    }
}
