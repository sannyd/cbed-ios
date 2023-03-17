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
    case register
    case singleSignOn(params: Parameters)
    case refreshToken(params: Parameters)
    case forgotPassword(params: Parameters)
    case deactivate
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
        case .refreshToken:
            return "/token-refresh/"
        case .forgotPassword:
            return "/request_reset_password"
        case .deactivate:
            return "/deactivate"
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
             .singleSignOn(let params),
             .refreshToken(let params),
             .forgotPassword(let params):
            let encoding = Alamofire.JSONEncoding.default
            request = try encoding.encode(request, with: params)
        default:
            break
        }

        return request
    }
}
