//
//  ColorContext.swift
//  CBED
//
//  Created by Jimmy Hoang on 26/06/2021.
//

import Foundation

struct ColorContext {
    enum Mode {
        case light, dark
    }

    enum Elevation {
        case base, elevated
    }

    enum AccessibilityContrast {
        case normal, high
    }

    let mode: Mode
    let elevation: Elevation
    let accessibilityContrast: AccessibilityContrast
}
