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
        if let headers = request.request?.headers {
            Log.networkRequest(headers)
        }
    }
    
    func request<Value>(
        _ request: DataRequest,
        didParseResponse response: DataResponse<Value, AFError>
    ) {
        
        if let error = response.error {
            Log.networkError(error)
        }
        
        guard let data = response.data else {
            return
        }
        if let json = try? JSONSerialization
            .jsonObject(with: data, options: .mutableContainers) {
            Log.networkRepsonse(json)
        }
    }
}


final class APIClient: SessionDelegate, @unchecked Sendable {
    static let shared = APIClient()
    var sessionManager: Session?
    var nonBearer: Session?
    
    init() {
        let monitor = NetworkLogger()
        let interceptor = JWTAccessTokenAdapter()
        sessionManager = Session(interceptor: interceptor,
                                 eventMonitors: [monitor])
        nonBearer = Session(eventMonitors: [monitor])
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
                        self.handleError(error: error,
                                         responseData: response.data,
                                         single: single)
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    func requestAsDict(_ urlConvertible: URLRequestConvertible) -> Single<[[String: Any]]> {
        return Single<[[String: Any]]>.create { single in
            let request = self.nonBearer!.request(urlConvertible)
                .validate()
                .validate(statusCode: 200..<300)
                .responseData { response in
                    if let data = response.data,
                       let dict = try? JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [[String: Any]] {
                        
                        single(.success(dict))
                    } else {
                        single(.failure(CustomError.CannotGetParams))
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    func upload<T: Decodable>(multipartFormData: MultipartFormData,
                              urlConvertible: URLRequestConvertible,
                              dateFormatters: [DateFormatter] = [.iso8601Full]) -> Single<T> {
        return Single<T>.create { single in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategyFormatters = dateFormatters
            
            let request = self.sessionManager!.upload(multipartFormData: multipartFormData, with: urlConvertible)
                .validate()
                .validate(statusCode: 200..<300)
                .responseDecodable(decoder: decoder) { (response: DataResponse<T, AFError>) in
                    switch response.result {
                    case .success(let result):
                        single(.success(result))
                    case .failure(let error):
                        self.handleError(error: error,
                                         responseData: response.data,
                                         single: single)
                    }
                }
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
    func requestWithoutValidation<T: Decodable>(_ urlConvertible: URLRequestConvertible,
                               dateFormatters: [DateFormatter] = [.iso8601Full]) -> Single<T> {
        return Single<T>.create { single in
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategyFormatters = dateFormatters
            
            let request = self.sessionManager!.request(urlConvertible)
                .responseDecodable(decoder: decoder) { (response: DataResponse<T, AFError>) in
                    switch response.result {
                    case .success(let result):
                        single(.success(result))
                    case .failure(let error):
                        self.handleError(error: error,
                                         responseData: response.data,
                                         single: single)
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
                        self.handleError(error: error,
                                         responseData: response.data,
                                         single: single)
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
        let interceptor = JWTAccessTokenAdapter()
        sessionManager = Session(interceptor: interceptor,
                                 eventMonitors: [monitor])
    }
    
    private func handleError<T>(error: Error,
                                responseData: Data?,
                                single: (Result<T, Error>) -> Void) {
        let decoder = JSONDecoder()
        if let data = responseData {
            if let serverError = try? decoder.decode(ServerError.self, from: data) {
                single(.failure(serverError))
            } else if let forgotError = try? decoder.decode(ForgotPasswordError.self, from: data) {
                single(.failure(forgotError))
            } else if let dictError = try? decoder.decode([String: [String]].self, from: data) {
                single(.failure(ServerError.init(code: "400", detail: dictError.first?.value.first ?? "Unknown error")))
            } else {
                single(.failure(error))
            }
        } else {
            single(.failure(error))
        }
    }
}

