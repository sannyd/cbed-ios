//
//  SingleSignOnResponseM.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import Foundation

struct SingleSignOnResponseM: Decodable {
    let accessToken: String
    let ssoType: SSOType
    let token: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case ssoType = "sso_type"
        case token
    }
}
