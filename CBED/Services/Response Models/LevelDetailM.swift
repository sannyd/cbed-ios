//
//  SectionM.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation

struct LevelDetailM: Codable {
    let id: Int
    let name: String?
    let sections: [SectionM]?
}

// MARK: - Section
struct SectionM: Codable {
    let id: Int
    let name: String?
    let lastResult: LastResultM?
    let isAvailable: Bool?
    let order: Int?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case lastResult = "last_result"
        case isAvailable = "is_available"
        case order = "order"
    }
}

// MARK: - LastResult
struct LastResultM: Codable {
    let correct: Int?
    let total: Int?
}
