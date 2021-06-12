//
//  AuthRouter.swift
//  CBED
//
//  Created by Jimmy Hoang on 6/11/21.
//

import Foundation
import Alamofire

enum AuthRouter {
    case signIn(params: Parameters)
    case register(params: Parameters)
    case singleSignOn(params: Parameters)
}

// MARK: - TargetType: Moya compatible
extension AuthRouter: URLRequestConvertible {
    var baseURL: URL {
        let apiUrl = Environment.apiUrl + "/auth"
        
        guard let url = URL(string: apiUrl) else { fatalError("Cannot configure Base URL")}
        return url
    }
    
    var path: String {
        switch self {
        case .signIn:
            return "/signin"
        case .register:
            return "/register"
        case  .singleSignOn:
            return "/single_sign_on"
        }
    }
    
    var method: HTTPMethod {
        return .post
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        
        switch self {
        case .signIn(let params),
             .register(let params),
             .singleSignOn(let params):
            let encoding = Alamofire.JSONEncoding.default
            request = try encoding.encode(request, with: params)
        }
        
        return request
    }
}
