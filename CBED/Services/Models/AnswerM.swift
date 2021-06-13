//
//  AnswerM.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation

struct AnswerM: Decodable {
    let id: Int
    let created: String?
    let modified: String?
    let content: String?
    let discussion: String?
    let isCorrect: Bool?
    let order: Int?
    let question: Int?
}
