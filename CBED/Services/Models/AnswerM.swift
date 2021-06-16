//
//  AnswerM.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation

struct AnswerM: Decodable {
    let id: Int?
    let created: String?
    let modified: String?
    let content: String?
    let discussion: String?
    let isCorrect: Bool?
    let order: Int?
    let question: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case created = "created"
        case modified = "modified"
        case content = "content"
        case discussion = "discussion"
        case isCorrect = "is_correct"
        case order = "order"
        case question = "question"
    }
}
