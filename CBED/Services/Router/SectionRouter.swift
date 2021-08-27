//
//  SectionRouter.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation
import Alamofire

enum SectionRouter {
    case getSectionByID(_ id: Int)
    case searchSection(params: Parameters)
    case searchEssays(params: Parameters)
    case saveSectionResult(id: Int,
                           correct: Int,
                           total: Int)
}

// MARK: - TargetType: Moya compatible
extension SectionRouter: URLRequestConvertible {
    var baseURL: URL {
        let apiUrl = Environment.apiUrl + "/sections"
        
        guard let url = URL(string: apiUrl) else { fatalError("Cannot configure Base URL")}
        return url
    }
    
    var path: String {
        switch self {
        case .getSectionByID(let id):
            return "/\(id)/"
        case .searchSection:
            return "/"
        case .searchEssays:
            return "/essays/"
        case .saveSectionResult(let id, _, _):
            return "/\(id)/save_result/"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .saveSectionResult:
            return .post
        default:
            return .get
        }
    }
    
    func asURLRequest() throws -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var request = URLRequest(url: url)
        request.method = method
        
        switch self {
        case .searchSection(let params),
             .searchEssays(let params):
            let encoder = Alamofire.URLEncoding.queryString
            request = try encoder.encode(request, with: params)
        case .saveSectionResult(_,
                                let correct,
                                let total):
            let encoder = Alamofire.URLEncoding.httpBody
            request = try encoder.encode(request, with: ["correct": correct,
                                                         "total": total])
        default:
            break
        }
        
        return request
    }
}

