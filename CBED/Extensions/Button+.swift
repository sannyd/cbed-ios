//
//  Button+.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 5/20/21.
//

import UIKit
import RxSwift

// MARK: Rx
extension UIButton {
    static func installTapFeedbackSwizzle() {
        _ = buttonTapFeedbackSwizzleToken
    }

    var rxButtonTapped: Observable<Void> {
        return rx
            .tap
            .asObservable()
    }

    private static let buttonTapFeedbackSwizzleToken: Void = {
        Swizzler.swizzleSelector(classToSwizzle: UIButton.self,
                                 originalSelector: #selector(sendAction(_:to:for:)),
                                 swizzledSelector: #selector(cbed_sendAction(_:to:for:)))
    }()

    @objc dynamic
    private func cbed_sendAction(_ action: Selector, to target: Any?, for event: UIEvent?) {
        if shouldPlayTapFeedback(for: event) {
            AudioFeedbackManager.shared.playButtonTapIfEnabled()
        }

        cbed_sendAction(action, to: target, for: event)
    }

    private func shouldPlayTapFeedback(for event: UIEvent?) -> Bool {
        guard isEnabled,
              window != nil,
              event != nil else {
            return false
        }

        return true
    }
}
