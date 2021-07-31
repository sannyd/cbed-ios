//
//  ScoreboardResponseM.swift
//  ScoreboardResponseM
//
//  Created by Jimmy Hoang on 28/07/2021.
//

import Foundation

struct ScoreboardResponseM: Codable {
    let babyBarJune: [ScoreM]
    let babyBarOct: [ScoreM]
    let proBarFeb: [ScoreM]
    let proBarJuly: [ScoreM]

    enum CodingKeys: String, CodingKey {
        case babyBarJune = "baby_bar_june"
        case babyBarOct = "baby_bar_oct"
        case proBarFeb = "pro_bar_feb"
        case proBarJuly = "pro_bar_july"
    }
}

struct ScoreM: Codable {
    let id: Int
    let name: String?
    let avatar: String?
    let points: Int
    let lastSectionName: String?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case avatar = "avatar"
        case points = "points"
        case lastSectionName = "last_section_name"
    }
}
