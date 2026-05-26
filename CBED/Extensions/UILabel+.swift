//
//  UILabel+.swift
//  CBED
//
//  Created by Jimmy Hoang on 10/07/2021.
//

import UIKit
import ObjectiveC.runtime

private var appBaseFontKey: UInt8 = 0

private func storedBaseFont(for object: NSObject) -> UIFont? {
    objc_getAssociatedObject(object, &appBaseFontKey) as? UIFont
}

private func setStoredBaseFont(_ font: UIFont, for object: NSObject) {
    objc_setAssociatedObject(object, &appBaseFontKey, font, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
}

private func appScaledFont(from baseFont: UIFont) -> UIFont {
    baseFont.withSize(baseFont.pointSize * Storage.appFontSize.scale)
}

extension UIFont {
    static func appFont(name: String, size: CGFloat) -> UIFont {
        let baseFont = UIFont(name: name, size: size) ?? .systemFont(ofSize: size)
        return appScaledFont(from: baseFont)
    }
}

extension UILabel {
    func scaledFont(style: UIFont.TextStyle) {
        let scaledFont = ScaledFont(fontName: "Lato")
        applyAppFontScaling(baseFont: scaledFont.font(forTextStyle: style), adjustsForContentSizeCategory: true)
    }
    
    func applyAppFontScaling() {
        applyAppFontScaling(baseFont: font, adjustsForContentSizeCategory: adjustsFontForContentSizeCategory)
    }
    
    private func applyAppFontScaling(baseFont: UIFont, adjustsForContentSizeCategory: Bool) {
        let originalFont = storedBaseFont(for: self) ?? baseFont
        if storedBaseFont(for: self) == nil {
            setStoredBaseFont(originalFont, for: self)
        }
        font = appScaledFont(from: originalFont)
        self.adjustsFontForContentSizeCategory = adjustsForContentSizeCategory
    }

    func applyScoreboardLevelColor(for levelText: String?,
                                   defaultColor: UIColor = Constants.PrimaryTextColor) {
        text = levelText

        guard let levelText else {
            textColor = defaultColor
            return
        }

        let lowercasedText = levelText.lowercased()
        guard let levelRange = lowercasedText.range(of: "level ") else {
            textColor = defaultColor
            return
        }

        let levelSuffix = lowercasedText[levelRange.upperBound...]
        let levelDigits = levelSuffix.prefix { $0.isNumber }

        guard let levelNumber = Int(levelDigits) else {
            textColor = defaultColor
            return
        }

        switch levelNumber {
        case 7:
            textColor = UIColor(hex: "#D4AF37") ?? defaultColor
        case 6:
            textColor = UIColor(hex: "#C0C0C0") ?? defaultColor
        case 5:
            textColor = UIColor(hex: "#CD7F32") ?? defaultColor
        default:
            textColor = defaultColor
        }
    }
}

extension UITextView {
    func scaledFont(style: UIFont.TextStyle) {
        let scaledFont = ScaledFont(fontName: "Lato")
        applyAppFontScaling(baseFont: scaledFont.font(forTextStyle: style), adjustsForContentSizeCategory: true)
    }
    
    func applyAppFontScaling() {
        applyAppFontScaling(baseFont: font ?? .systemFont(ofSize: 14), adjustsForContentSizeCategory: adjustsFontForContentSizeCategory)
    }
    
    private func applyAppFontScaling(baseFont: UIFont, adjustsForContentSizeCategory: Bool) {
        let originalFont = storedBaseFont(for: self) ?? baseFont
        if storedBaseFont(for: self) == nil {
            setStoredBaseFont(originalFont, for: self)
        }
        font = appScaledFont(from: originalFont)
        self.adjustsFontForContentSizeCategory = adjustsForContentSizeCategory
    }
}

extension UITextField {
    func applyAppFontScaling() {
        let baseFont = font ?? .systemFont(ofSize: 14)
        let originalFont = storedBaseFont(for: self) ?? baseFont
        if storedBaseFont(for: self) == nil {
            setStoredBaseFont(originalFont, for: self)
        }
        font = appScaledFont(from: originalFont)
    }
}
