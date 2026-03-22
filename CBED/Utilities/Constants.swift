//
//  Constants.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 2/25/21.
//

import Foundation
import UIKit

enum Membership {
    case pro
    case baby
    case free
}

enum InAppPurchaseMonth: String, CaseIterable {
    case ProBarFeb = "com.barexamdrills.app.probarfeb"
    case ProBarJul = "com.barexamdrills.app.probarjuly"
    case BabyBarJun = "com.barexamdrills.app.babybarjune"
    case BabyBarOct = "com.barexamdrills.app.babybaroct"
    
    var monthString: String {
        switch self {
        case .ProBarFeb:
            return "February"
        case .ProBarJul:
            return "July"
        case .BabyBarJun:
            return "June"
        case .BabyBarOct:
            return "October"
        }
    }
    
    var name: String {
        switch self {
        case .ProBarFeb:
            return "Pro Bar - February"
        case .ProBarJul:
            return "Pro Bar - July"
        case .BabyBarJun:
            return "Baby Bar - June"
        case .BabyBarOct:
            return "Baby Bar - October"
        }
    }
    
    var purchaseID: String {
        switch self {
        case .ProBarFeb:
            return "com.barexamdrills.app.probarfeb"
        case .ProBarJul:
            return "com.barexamdrills.app.probarjuly"
        case .BabyBarJun:
            return "com.barexamdrills.app.babybarjune"
        case .BabyBarOct:
            return "com.barexamdrills.app.babybaroct"
        }
    }
    
    static func getMonthType(from purchaseID: String) -> InAppPurchaseMonth? {
        return InAppPurchaseMonth(rawValue: purchaseID)
    }
}

enum ScoreboardType: String {
    case ProBarFeb
    case ProBarJul
    case BabyBarJun
    case BabyBarOct
    case emailZoom
}

struct Constants {
    static let states = ["Alaska",
                      "Alabama",
                      "Arkansas",
                      "American Samoa",
                      "Arizona",
                      "California",
                      "Colorado",
                      "Connecticut",
                      "District of Columbia",
                      "Delaware",
                      "Florida",
                      "Georgia",
                      "Guam",
                      "Hawaii",
                      "Iowa",
                      "Idaho",
                      "Illinois",
                      "Indiana",
                      "Kansas",
                      "Kentucky",
                      "Louisiana",
                      "Massachusetts",
                      "Maryland",
                      "Maine",
                      "Michigan",
                      "Minnesota",
                      "Missouri",
                      "Mississippi",
                      "Montana",
                      "North Carolina",
                      " North Dakota",
                      "Nebraska",
                      "New Hampshire",
                      "New Jersey",
                      "New Mexico",
                      "Nevada",
                      "New York",
                      "Ohio",
                      "Oklahoma",
                      "Oregon",
                      "Pennsylvania",
                      "Puerto Rico",
                      "Rhode Island",
                      "South Carolina",
                      "South Dakota",
                      "Tennessee",
                      "Texas",
                      "Utah",
                      "Virginia",
                      "Virgin Islands",
                      "Vermont",
                      "Washington",
                      "Wisconsin",
                      "West Virginia",
                      "Wyoming"]
    
    struct Storyboards {
        static let Login = UIStoryboard(name: "Login", bundle: nil)
        static let Home = UIStoryboard(name: "Home", bundle: nil)
        static let LiveTask = UIStoryboard(name: "LiveTask", bundle: nil)
        static let AssignTask = UIStoryboard(name: "AssignTask", bundle: nil)
        static let FinishedTask = UIStoryboard(name: "FinishedTask", bundle: nil)
    }
    
    struct Font {
        static let LatoRegular = "Lato-Regular"
        static let LatoBold = "Lato-Bold"
    }
    
    static let ColorA2A2A2 = #colorLiteral(red: 0.6352941176, green: 0.6352941176, blue: 0.6352941176, alpha: 1)
    static let PrimaryBlue = UIColor.dynamicColor { context in
        switch context.mode {
        case .light:
            return #colorLiteral(red: 0.1607843137, green: 0.3568627451, blue: 0.8784313725, alpha: 1)
        case .dark:
            return #colorLiteral(red: 0.3058823529, green: 0.4549019608, blue: 0.8509803922, alpha: 1)
        }
    }

    static let ColorC4C4C4 = #colorLiteral(red: 0.768627451, green: 0.768627451, blue: 0.768627451, alpha: 1)
    static let primaryTextfieldColor = #colorLiteral(red: 0.662745098, green: 0.7254901961, blue: 0.8039215686, alpha: 1)
    static let ColorE0293F = #colorLiteral(red: 0.8784313725, green: 0.1607843137, blue: 0.2470588235, alpha: 1)
    static let PrimaryTextColor = UIColor.dynamicColor { context in
        switch context.mode {
        case .light:
            return #colorLiteral(red: 0.2117647059, green: 0.2039215686, blue: 0.2392156863, alpha: 1)
        case .dark:
            return .white
        }
    }
    
    static let BackgroundColor = UIColor.dynamicColor { context in
        switch context.mode {
        case .light:
            return .white
        case .dark:
            return #colorLiteral(red: 0.1843137255, green: 0.1725490196, blue: 0.3254901961, alpha: 1)
        }
    }
    
    static let CellColor = UIColor.dynamicColor { context in
        switch context.mode {
        case .light:
            return .white
        case .dark:
            return #colorLiteral(red: 0.2235294118, green: 0.2078431373, blue: 0.4470588235, alpha: 1)
        }
    }
    
    static let SecondarySurfaceColor = UIColor.dynamicColor { context in
        switch context.mode {
        case .light:
            return #colorLiteral(red: 0.9490196078, green: 0.9568627451, blue: 0.9764705882, alpha: 1)
        case .dark:
            return #colorLiteral(red: 0.2705882353, green: 0.2509803922, blue: 0.5098039216, alpha: 1)
        }
    }
    
    static let CardShadowColor = UIColor.dynamicColor { context in
        switch context.mode {
        case .light:
            return UIColor.black.withAlphaComponent(0.12)
        case .dark:
            return UIColor.black.withAlphaComponent(0.35)
        }
    }
    
    struct TimeFormat {
        static let iso8601Full = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        static let hmma = "h:mm a"
    }
    
    struct UserDefaultKeys {
        static let AvailableDriver = "AvailableDriver"
        static let ServiceCoverages = "ServiceCoverages"
        static let DefaultLocation = "DefaultLocation"
        static let RecentSearch = "RecentSearch"
    }
}
