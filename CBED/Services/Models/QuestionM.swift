//
//  QuestionM.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation

struct QuestionM: Decodable {
    let id: Int
    let answers: [AnswerM]?
    let created: String?
    let modified: String?
    let content: String?
    let order: Int?
    let section: Int?
}
