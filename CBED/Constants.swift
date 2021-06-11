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
    
    static let ColorA2A2A2 = UIColor(hex: "#A2A2A2")!
    
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
