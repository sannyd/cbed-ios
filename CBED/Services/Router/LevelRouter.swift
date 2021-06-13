//
//  LevelRouter.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation
import Alamofire

enum LevelRouter {
    case getAllLevels
    case getLevelByID(_ id: String)
}

// MARK: - TargetType: Moya compatible
extension LevelRouter: URLRequestConvertible {
    var baseURL: URL {
        let apiUrl = Environment.apiUrl + "/levels"
        
        guard let url = URL(string: apiUrl) else { fatalError("Cannot configure Base URL")}
        return url
    }
    
    var path: String {
        switch self {
        case .getAllLevels:
            return "/"
        case .getLevelByID(let id):
            return "/\(id)/"
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
