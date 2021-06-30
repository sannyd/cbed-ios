//
//  SearchSectionRequestM.swift
//  CBED
//
//  Created by Jimmy Hoang on 30/06/2021.
//

import Foundation

struct SearchSectionRequestM: BaseRequestM, Encodable {
    let search: String
    let level: String
    let limit: Int
    let offset: Int
}
