//
//  RegisterResponseM.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import Foundation

struct RegisterResponseM: Decodable {
    let email: String
    let name: String
    let state: String
    let avatar: String?
}
