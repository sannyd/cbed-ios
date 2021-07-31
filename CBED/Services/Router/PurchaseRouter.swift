//
//  PurchaseRouter.swift
//  CBED
//
//  Created by Jimmy Hoang on 29/07/2021.
//

import Foundation
import Alamofire

enum PurchaseRouter {
    case purchaseMembership(params: Parameters)
}

// MARK: - TargetType: Moya compatible
extension PurchaseRouter: URLRequestConvertible {
    var baseURL: URL {
        let apiUrl = Environment.apiUrl
        
        guard let url = URL(string: apiUrl) else { fatalError("Cannot configure Base URL")}
        return url
    }
    
    var path: String {
        switch self {
        case .purchaseMembership:
            return "/purchase"
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
        case .purchaseMembership(let params):
            let encoding = Alamofire.JSONEncoding.default
            request = try encoding.encode(request, with: params)
        }
        
        return request
    }
}
