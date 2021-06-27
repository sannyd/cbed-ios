//
//  ColorContext+UITraitCollection.swift
//  CBED
//
//  Created by Jimmy Hoang on 26/06/2021.
//

import UIKit

extension ColorContext {
    @available(iOS 13.0, *)
    init(_ traitCollection: UITraitCollection,
         defaultMode: Mode = .light,
         defaultElevation: Elevation = .base,
         defaultAccessibilityContrast: AccessibilityContrast = .normal) {
        mode = {
            switch traitCollection.userInterfaceStyle {
            case .light: return .light
            case .dark: return .dark
            case .unspecified: return defaultMode
            @unknown default: return defaultMode
            }
        }()

        elevation = {
            switch traitCollection.userInterfaceLevel {
            case .base: return .base
            case .elevated: return .elevated
            case .unspecified: return defaultElevation
            @unknown default: return defaultElevation
            }
        }()

        accessibilityContrast = {
            switch traitCollection.accessibilityContrast {
            case .normal: return .normal
            case .high: return .high
            case .unspecified: return defaultAccessibilityContrast
            @unknown default: return defaultAccessibilityContrast
            }
        }()
    }
}
