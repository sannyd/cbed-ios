//
//  UpdateProfileRequestM.swift
//  CBED
//
//  Created by Jimmy Hoang on 8/29/21.
//

import Foundation

struct UpdateProfileRequestM: BaseRequestM, Encodable {
    let name: String
    let state: String
    let phone: String
    
    enum CodingKeys: String, CodingKey {
        case name, state
        case phone = "phone_number"
    }
}
