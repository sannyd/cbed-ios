//
//  UILabel+.swift
//  CBED
//
//  Created by Jimmy Hoang on 10/07/2021.
//

import UIKit

extension UILabel {
    func scaledFont(style: UIFont.TextStyle) {
        let scaledFont = ScaledFont(fontName: "Lato")
        self.font = scaledFont.font(forTextStyle: style)
        self.adjustsFontForContentSizeCategory = true
    }
}

extension UITextView {
    func scaledFont(style: UIFont.TextStyle) {
        let scaledFont = ScaledFont(fontName: "Lato")
        self.font = scaledFont.font(forTextStyle: style)
        self.adjustsFontForContentSizeCategory = true
    }
}
