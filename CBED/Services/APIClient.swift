//
//  APIClient.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 2/26/21.
//

import Alamofire
import RxSwift
import Foundation

final class APIClient: SessionDelegate {
    static let shared = APIClient()
    var sessionManager: Session?
    
    init() {
        if let accessToken = Storage.accessToken {
            let interceptor = JWTAccessTokenAdapter(accessToken: accessToken)
            sessionManager = Session(interceptor: interceptor)
        } else {
            sessionManager = Session()
        }
    }
    
    func request<T: Decodable>(_ urlConvertible: URLRequestConvertible,
                               dateFormatters: [DateFormatter] = [.iso8601Full]) -> Single<T> {
        return Single<T>.create { single in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategyFormatters = dateFormatters
            
            let request = self.sessionManager!.request(urlConvertible)
                .validate()
                .validate(statusCode: 200..<300)
                .responseDecodable(decoder: decoder) { (response: DataResponse<T, AFError>) in
                    switch response.result {
                    case .success(let result):
                        single(.success(result))
                    case .failure(let error):
                        single(.failure(error))
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    func request(_ urlConvertible: URLRequestConvertible) -> Single<Void> {
        return Single.create { single in
            let request = self.sessionManager!.request(urlConvertible)
                .validate()
                .validate(statusCode: 200..<300)
                .responseJSON { response in
                    switch response.result {
                    case .success:
                        single(.success(()))
                    case .failure(let error):
                        single(.failure(error))
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    func resetSession() {
        sessionManager = nil
        sessionManager?.cancelAllRequests()
        sessionManager = Session()
    }
    
    func readInterceptor() {
        sessionManager = nil
        sessionManager?.cancelAllRequests()
        if let accessToken = Storage.accessToken {
            let interceptor = JWTAccessTokenAdapter(accessToken: accessToken)
            sessionManager = Session(interceptor: interceptor)
        } else {
            sessionManager = Session()
        }
    }
    
//    static func request(_ urlConvertible: URLRequestConvertible) -> Completable {
//        return Completable.create { observer in
//            let request = AF.request(urlConvertible)
//                .validate()
//                .validate(statusCode: 200..<300)
//                .responseJSON { (response) in
//                    switch response.result {
//                    case .success:
//                        observer(.completed)
//                    case .failure(let error):
//                        observer(.error(error))
//                    }
//                }
//            
//            return Disposables.create {
//                request.cancel()
//            }
//        }
//    }
}
