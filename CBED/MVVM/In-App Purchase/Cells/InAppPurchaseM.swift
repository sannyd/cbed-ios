//
//  InAppPurchaseM.swift
//  CBED
//
//  Created by Jimmy Hoang on 07/07/2021.
//

import Foundation

enum InAppPurchaseType {
    case ProBar
    case BabyBar
    
    var title: String {
        switch self {
        case .ProBar:
            return "Bar Exam"
        case .BabyBar:
            return "Baby Bar"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .ProBar:
            return "Best Deal"
        case .BabyBar:
            return ""
        }
    }
    
    var promotionPrice: Double {
        switch self {
        case .ProBar:
            return 1599.99
        case .BabyBar:
            return 799.99
        }
    }
    
    var realPrice: Double {
        switch self {
        case .ProBar:
            return 999.99
        case .BabyBar:
            return 399.99
        }
    }
    
    var descriptions: [String] {
        switch self {
        case .ProBar:
            return ["56 MBE levels",
                    "Essay Drills + Videos",
                    "PT Drills + Videos"]
        case .BabyBar:
            return ["21 MBE levels",
                    "Essay Drills + Videos"]
        }
    }
    
    var months: (leftData: InAppPurchaseMonth, rightData: InAppPurchaseMonth) {
        switch self {
        case .ProBar:
            return (InAppPurchaseMonth.ProBarFeb,
                    InAppPurchaseMonth.ProBarJul)
        case .BabyBar:
            return (InAppPurchaseMonth.BabyBarJun,
                    InAppPurchaseMonth.BabyBarOct)
        }
    }
}

struct InAppPurchaseM {
    let title: String
    let subtitle: String?
    let promotionPrice: Double
    let realPrice: Double
    let descriptions: [String]
}
