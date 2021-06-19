//
//  APIClient.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 2/26/21.
//

import Alamofire
import RxSwift
import Foundation

class NetworkLogger: EventMonitor {
    //1
    let queue = DispatchQueue(label: "com.cbed.networklogger")
    //2
    func requestDidFinish(_ request: Request) {
        Log.networkRequest(request.description)
    }
    
    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        guard let data = response.data else {
            return
        }
        if let json = try? JSONSerialization
            .jsonObject(with: data, options: .mutableContainers) {
            Log.networkRepsonse(json)
        }
    }
}


final class APIClient: SessionDelegate {
    static let shared = APIClient()
    var sessionManager: Session?
    
    init() {
        let monitor = NetworkLogger()
        if let accessToken = Storage.accessToken {
            let interceptor = JWTAccessTokenAdapter(accessToken: accessToken)
            sessionManager = Session(interceptor: interceptor, eventMonitors: [monitor])
        } else {
            sessionManager = Session(eventMonitors: [monitor])
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
                        let decoder = JSONDecoder()
                        if let data = response.data,
                           let serverError = try? decoder.decode(ServerError.self, from: data) {
                            single(.failure(serverError))
                        } else {
                            single(.failure(error))
                        }
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
        let monitor = NetworkLogger()
        if let accessToken = Storage.accessToken {
            let interceptor = JWTAccessTokenAdapter(accessToken: accessToken)
            sessionManager = Session(interceptor: interceptor, eventMonitors: [monitor])
        } else {
            sessionManager = Session(eventMonitors: [monitor])
        }
    }
}
