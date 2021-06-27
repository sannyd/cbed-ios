//
//  UIColor+BackwardsCompatibleResolvedColor.swift
//  CBED
//
//  Created by Jimmy Hoang on 26/06/2021.
//

import UIKit

extension UIColor {
    func backwardsCompatibleResolvedColor(with traitCollection: UITraitCollection) -> UIColor {
        guard #available(iOS 13.0, *) else {
            return self
        }

        return resolvedColor(with: traitCollection)
    }
}
