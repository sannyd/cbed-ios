//
//  CustomError.swift
//  CBED
//
//  Created by Jimmy Hoang on 30/06/2021.
//

import Foundation

enum CustomError: Error {
    case CannotGetParams
    case CannotGetIAPReceiptData
    case CannotRestoreIAP
    
    var errorString: String {
        switch self {
        case .CannotGetParams:
            return "Cannot get parameters"
        case .CannotGetIAPReceiptData:
            return "Cannot get IAP receipt data string"
        case .CannotRestoreIAP:
            return "Previous purchase restore failed"
        }
    }
}
