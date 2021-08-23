
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
    private let disposeBag = DisposeBag()
    private let lock = NSRecursiveLock()
    private typealias RefreshCompletion = (_ succeeded: Bool, _ accessToken: String?) -> Void
    private typealias RequestRetryCompletion = (RetryResult) -> Void
    private var requestsToRetry: [RequestRetryCompletion] = []

    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Swift.Result<URLRequest, Error>) -> Void) {
        var urlRequest = urlRequest
        let isRequireBearer = urlRequest.url?.absoluteString.contains("auth") ?? false
        if !isRequireBearer {
            if let accessToken = Storage.accessToken {
                urlRequest.setValue("Bearer " + accessToken, forHTTPHeaderField: "Authorization")
            } else {
                completion(.failure(NSError(domain: "401", code: 401, userInfo: [:])))
            }
        }
        
        completion(.success(urlRequest))
    }
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        
        guard let response = request.task?.response as? HTTPURLResponse,
              response.statusCode == 401 || response.statusCode == 403 else {
            /// The request did not fail due to a 401 Unauthorized response.
            /// Return the original error and don't retry the request.
            return completion(.doNotRetry)
        }
        
        guard !(request.task?.response?.url?.absoluteString.contains("/auth/refresh") ?? true) else {
            DispatchQueue.main.async {
                self.showSingoutDialog()
            }
          
            return completion(.doNotRetry)
        }
        
        guard Storage.refreshToken != nil else {
            completion(.doNotRetryWithError(error))
            return
        }
        
        requestsToRetry.append(completion)
        
        refreshToken { [weak self] refreshResponse in
            guard let strongSelf = self else { return }
            if !refreshResponse {
                strongSelf.requestsToRetry.forEach { $0(.doNotRetry) }
                strongSelf.requestsToRetry.removeAll()
                
                DispatchQueue.main.async {
                    strongSelf.showSingoutDialog()
                }
            }
            
            strongSelf.lock.lock() ; defer { strongSelf.lock.unlock() }
  
            strongSelf.requestsToRetry.forEach { $0(.retry) }
            strongSelf.requestsToRetry.removeAll()
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
    
    private func showSingoutDialog() {
        UIAlertHelper.showAlertController(title: "Error",
                                          message: "Your session has expired. Please sign in again￼",
                                          cancel: "Sign Out",
                                          others: nil) { (_, _) in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            appDelegate.logout()
        }
    }
}
