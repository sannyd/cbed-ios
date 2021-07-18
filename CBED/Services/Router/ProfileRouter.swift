//
//  ProfileRouter.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/07/2021.
//

import Foundation
import Alamofire

enum ProfileRouter {
    case getProfileInfo
}

// MARK: - TargetType: Moya compatible
extension ProfileRouter: URLRequestConvertible {
    var baseURL: URL {
        let apiUrl = Environment.apiUrl + "/profile"
        
        guard let url = URL(string: apiUrl) else { fatalError("Cannot configure Base URL")}
        return url
    }
    
    var path: String {
        switch self {
        case .getProfileInfo:
            return "/info/"
        }
    }
    
    var method: HTTPMethod {
        return .get
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method

        return request
    }
}
