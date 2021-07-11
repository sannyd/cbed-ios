//
//  RegisterRequestM.swift
//  CBED
//
//  Created by Jimmy Hoang on 11/07/2021.
//

import Foundation

struct RegisterRequestM: BaseRequestM, Encodable {
    let name: String
    let email: String
    let password: String
    let state: String
}
