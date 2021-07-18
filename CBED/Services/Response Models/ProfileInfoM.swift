//
//  ProfileInfoM.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/07/2021.
//

import Foundation

struct ProfileInfoM: Codable {
    let email: String
    let avatar: String?
    let name: String
    let state: String
    let membership: String
    
    enum CodingKeys: String, CodingKey {
        case email = "email"
        case avatar = "avatar"
        case name = "name"
        case state = "state"
        case membership = "membership"
    }
}
