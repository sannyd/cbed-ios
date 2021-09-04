//
//  QuestionM.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation

struct QuestionM: Decodable, Equatable {
    let id: Int
    var answers: [AnswerM]?
    let created: String?
    let modified: String?
    let content: String?
    let order: Int?
    let section: Int?
    let youtubeURL: String?
    
    enum CodingKeys: String, CodingKey {
        case id, answers, created, modified, content, order, section
        case youtubeURL = "youtube_url"
    }
}
