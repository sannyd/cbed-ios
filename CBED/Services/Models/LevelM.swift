//
//  GetAllLevelsResponseM.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation

struct LevelM: Decodable {
    let id: Int
    let name: String?
    let order: Int?
}
