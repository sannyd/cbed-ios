import Foundation

enum InAppPurchaseType: String, Codable {
    case ProBarFeb = "Bar Exam - Feb"
    case ProBarJuly = "Bar Exam - July"
    case BabyBarJune = "Baby Bar - June"
    case BabyBarOct = "Baby Bar - Oct"
    
    var title: String {
        switch self {
        case .ProBarFeb: return "Bar Exam - February"
        case .ProBarJuly: return "Bar Exam - July"
        case .BabyBarJune: return "Baby Bar - June"
        case .BabyBarOct: return "Baby Bar - October"
        }
    }
    
    var subtitle: String? {
        switch self {
        case .ProBarFeb, .ProBarJuly:
            return "Best Deal"
        case .BabyBarOct, .BabyBarJune:
            return ""
        }
    }
    
    var promotionPrice: Double {
        switch self {
        case .ProBarFeb, .ProBarJuly:
            return 1599.99
        case .BabyBarOct, .BabyBarJune:
            return 799.99
        }
    }
    
    var realPrice: Double {
        switch self {
        case .ProBarFeb, .ProBarJuly:
            return 699.99
        case .BabyBarOct, .BabyBarJune:
            return 99.99
        }
    }
    
    var descriptions: [String] {
        switch self {
        case .ProBarFeb, .ProBarJuly:
            return ["56 MBE levels of 8 discrete MBE subjects.",
                    "Essay Drills + Videos",
                    "M/PT Drills + Videos",
                    "14 mixed 50 question sets."]
        case .BabyBarOct, .BabyBarJune:
            return ["21 MBE levels of Torts, Contracts and Criminal Law.",
                    "Essay Drills + Videos"]
        }
    }
    
    var inAppPurchaseMonth: InAppPurchaseMonth {
        switch self {
        case .ProBarFeb: return InAppPurchaseMonth.ProBarFeb
        case .ProBarJuly: return InAppPurchaseMonth.ProBarJul
        case .BabyBarJune: return InAppPurchaseMonth.BabyBarJun
        case .BabyBarOct: return InAppPurchaseMonth.BabyBarOct
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
