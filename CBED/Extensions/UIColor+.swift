//
//  UIColor+.swift
//  CleanArchitecture
//
//  Created by Tuan Truong on 10/24/19.
//  Copyright © 2019 Sun Asterisk. All rights reserved.
//

import UIKit

extension UIColor {
    convenience init?(hex: String) {
        let red, green, blue: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt32 = 0
                
                if scanner.scanHexInt32(&hexNumber) {
                    red = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
                    green = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
                    blue = CGFloat(hexNumber & 0x0000FF) / 255.0
                    
                    self.init(red: red, green: green, blue: blue, alpha: 1.0)
                    return
                }
            }
        }
        
        return nil
    }
    
    convenience init?(hex: String, alpha: Double) {
        let red, green, blue: CGFloat
        
        if hex.hasPrefix("#") {
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt32 = 0
                
                if scanner.scanHexInt32(&hexNumber) {
                    red = CGFloat((hexNumber & 0xFF0000) >> 16) / 255.0
                    green = CGFloat((hexNumber & 0x00FF00) >> 8) / 255.0
                    blue = CGFloat(hexNumber & 0x0000FF) / 255.0
                    
                    self.init(red: red, green: green, blue: blue, alpha: CGFloat(alpha))
                    return
                }
            }
        }
        
        return nil
    }
}
