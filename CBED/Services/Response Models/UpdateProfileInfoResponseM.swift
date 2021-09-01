//
//  UpdateProfileInfoResponseM.swift
//  CBED
//
//  Created by Jimmy Hoang on 8/29/21.
//

import Foundation

struct UpdateProfileInfoResponseM: Codable {
    let avatar: String?
    let name: String?
    let state: String?
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case avatar = "avatar"
        case name = "name"
        case state = "state"
        case phone = "phone_number"
    }
}
