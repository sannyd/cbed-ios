//
//  UIColor+DynamicColorContext.swift
//  CBED
//
//  Created by Jimmy Hoang on 26/06/2021.
//

import UIKit

extension UIColor {
    static func dynamicColor(provider: @escaping (ColorContext) -> UIColor,
                     defaultMode: ColorContext.Mode = .light,
                     defaultElevation: ColorContext.Elevation = .base,
                     defaultAccessibilityContrast: ColorContext.AccessibilityContrast = .normal) -> UIColor {
        guard #available(iOS 13.0, *) else {
            let colorContext = ColorContext(mode: defaultMode,
                                            elevation: defaultElevation,
                                            accessibilityContrast: defaultAccessibilityContrast)
            return provider(colorContext)
        }

        return UIColor { traitCollection -> UIColor in
            let colorContext = ColorContext(traitCollection)
            return provider(colorContext)
        }
    }
}
