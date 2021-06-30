//
//  SectionDetailM.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import Foundation

struct SectionDetailM: Decodable {
    let id: Int
    let name: String?
    let lastResult: LastResultM?
    let isAvailable: Bool?
    let youtubeUrls: [String]?
    let pdfUrls: [String]?
    let questions: [QuestionM]?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case lastResult = "last_result"
        case isAvailable = "is_available"
        case youtubeUrls = "youtube_urls"
        case pdfUrls = "pdf_urls"
        case questions = "questions"
    }
}
