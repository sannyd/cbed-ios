//
//  ScoreboardRouter.swift
//  ScoreboardRouter
//
//  Created by Jimmy Hoang on 28/07/2021.
//

import Foundation
import Alamofire

enum ScoreboardRouter {
    case getScoreboard
}

// MARK: - TargetType: Moya compatible
extension ScoreboardRouter: URLRequestConvertible {
    var baseURL: URL {
        let apiUrl = Environment.apiUrl
        
        guard let url = URL(string: apiUrl) else { fatalError("Cannot configure Base URL")}
        return url
    }
    
    var path: String {
        switch self {
        case .getScoreboard:
            return "/scoreboard"
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

