//
//  Validation+String.swift
//  ValidatedPropertyKit
//
//  Created by Sven Tiigi on 20.06.19.
//  Copyright © 2019 Sven Tiigi. All rights reserved.
//

import Foundation

extension String {
    func regularExpression(_ pattern: String,
                           options: NSRegularExpression.Options = .init(),
                           matchingOptions: NSRegularExpression.MatchingOptions = .init()) -> Bool {
        // Verify NSRegularExpression can be constructed with String Pattern
        guard let regularExpression = try? NSRegularExpression(pattern: pattern, options: options) else {
            // Otherwise return Validation with failure
            return false
        }
        let firstMatchIsAvailable = regularExpression.firstMatch(
            in: self,
            options: matchingOptions,
            range: .init(self.startIndex..., in: self)
        ) != nil
        // Check if first match is available
        if firstMatchIsAvailable {
            return true
        } else {
            return false
        }
    }
    
    func minLength(min: Int, message: String) -> Bool {
        if value.count >= min {
            return true
        } else {
            return false
        }
    }
}
