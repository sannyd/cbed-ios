//
//  SectionM.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation

struct SectionM: Decodable {
    let id: Int?
    let questions: [QuestionM]?
    let created: String?
    let modified: String?
    let name: String?
    let youtubeURL: String?
    let pdfURL: String?
    let order: Int?
    let level: Int?
}
