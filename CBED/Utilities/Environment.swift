//
//  Environment.swift
//  Cantec Driver
//
//  Created by Advesa Apple 2 on 2/7/20.
//  Copyright © 2020 Advesa. All rights reserved.
//

import Foundation

public enum Environment {
    enum Keys {
        enum Plist {
            static let apiUrl = "APP_API_URL"
        }
    }
    
    private static let infoDict: [String: Any] = {
        guard let dict = Bundle.main.infoDictionary else {
            fatalError("Plist not found")
        }
        return dict
    }()
    
    static let apiUrl: String = {
        guard let apiUrl = Environment.infoDict[Keys.Plist.apiUrl] as? String else {
            fatalError("Key is not found in Plist")
        }
        
        return apiUrl
    }()
}
