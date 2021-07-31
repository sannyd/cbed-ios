//
//  PurchaseMembershipRequestM.swift
//  CBED
//
//  Created by Jimmy Hoang on 30/07/2021.
//

import Foundation

struct PurchaseMembershipRequestM: BaseRequestM, Encodable {
    let receiptData: String
    
    enum CodingKeys: String, CodingKey {
        case receiptData = "receipt_data"
    }
}
