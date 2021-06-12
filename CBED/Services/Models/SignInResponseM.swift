//
//  SignInResponseM.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import Foundation

struct SignInResponseM: Decodable {
    // MARK: - Token
    struct Token: Decodable {
        let refresh, access: String
    }
    
    let email: String
    let token: Token
}


