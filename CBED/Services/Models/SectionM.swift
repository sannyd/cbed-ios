//
//  SectionM.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation

struct SectionM: Decodable {
    let id: Int?
    let created: String?
    let modified: String?
    let name: String?
    let youtubeURL: String?
    let pdfURL: String?
    let order: Int?
    let level: Int?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case created = "created"
        case modified = "modified"
        case name = "name"
        case youtubeURL = "youtube_url"
        case pdfURL = "pdf_url"
        case order = "order"
        case level = "level"
    }
}
