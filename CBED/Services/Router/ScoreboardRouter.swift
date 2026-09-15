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
    
    /// URL path. Must match the `path(...)` entry in `config/api_router.py`.
    /// - iOS 11.0 ship target = `/scoreboard` → ScoreBoardV110View
    /// - iOS 11.1 ship target = `/scoreboard-111` → ScoreBoardV111View
    var path: String {
        switch self {
        case .getScoreboard:
            return "/scoreboard-111"
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

