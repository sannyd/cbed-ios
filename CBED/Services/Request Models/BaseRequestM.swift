//
//  BaseRequestM.swift
//  CBED
//
//  Created by Jimmy Hoang on 30/06/2021.
//

import Foundation
import Alamofire

protocol BaseRequestM where Self: Encodable {
    func toParams() -> Parameters?
}

extension BaseRequestM {
    func toParams() -> Parameters? {
        return try? self.asDictionary()
    }
}
