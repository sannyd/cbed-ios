//
//  Constants.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 2/25/21.
//

import Foundation
import UIKit

struct Constants {
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
