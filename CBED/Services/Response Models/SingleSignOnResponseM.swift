//
//  SingleSignOnResponseM.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import Foundation

struct SingleSignOnResponseM: Decodable {
    struct Token: Decodable {
        let refresh, access: String
    }
    let token: Token
}
