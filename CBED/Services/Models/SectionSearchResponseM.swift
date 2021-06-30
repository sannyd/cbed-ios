//
//  SectionSearchResponseM.swift
//  CBED
//
//  Created by Jimmy Hoang on 24/06/2021.
//

import Foundation

struct SectionSearchResponseM: Codable {
    let count: Int
    let next, previous: String?
    let results: [SearchResultM]
}

// MARK: - Result
struct SearchResultM: Codable {
    let id: Int
    let name: String?
    let subtitle: String?
    let image: String?
    let order: Int?
    let levelName: String?
    let isAvailable: Bool?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case subtitle = "subtitle"
        case image = "image"
        case order = "order"
        case levelName = "level_name"
        case isAvailable = "is_available"
    }
}
