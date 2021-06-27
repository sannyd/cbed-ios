//
//  EKAttributes.swift
//  CantecCourier
//
//  Created by Jimmy Hoang on 10/6/20.
//

import SwiftEntryKit

extension EKAttributes {
    static func createCustomAlertAttributes(isDismissable: Bool = true) -> EKAttributes {
        var attributes = EKAttributes()
        attributes.position = .center
        attributes.displayDuration = .infinity
        attributes.entryBackground = .color(color: .white)
        attributes.screenBackground = .color(color: EKColor(UIColor.black.withAlphaComponent(0.5)))
        attributes.screenInteraction = .absorbTouches
        attributes.entryInteraction = .absorbTouches
        if !isDismissable {
            attributes.scroll = .disabled
        }
        let widthConstraint = EKAttributes.PositionConstraints.Edge.offset(value: 20)
        let heightConstraint = EKAttributes.PositionConstraints.Edge.intrinsic
        attributes.positionConstraints.size = .init(width: widthConstraint, height: heightConstraint)
        attributes.positionConstraints.maxSize = .init(width: .constant(value: UIScreen.main.bounds.width),
                                                       height: .offset(value: 200))
        attributes.roundCorners = .all(radius: 10)
        attributes.shadow = .active(with: .init(color: .black,
                                                opacity: 0.1,
                                                radius: 6,
                                                offset: .init(width: 0, height: 1)))
        
        attributes.entranceAnimation = .init(
            scale: .init(
                from: 0.9,
                to: 1,
                duration: 0.4,
                spring: .init(damping: 0.8, initialVelocity: 0)
            ),
            fade: .init(
                from: 0,
                to: 1,
                duration: 0.3
            )
        )
        attributes.exitAnimation = .init(
            scale: .init(
                from: 1,
                to: 0.4,
                duration: 0.4,
                spring: .init(damping: 1, initialVelocity: 0)
            ),
            fade: .init(
                from: 1,
                to: 0,
                duration: 0.2
            )
        )
        return attributes
    }
}
