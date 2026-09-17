//
//  TutorsSheetObserver.swift
//  CBED
//
//  V11.1 — singleton UIAdaptivePresentationControllerDelegate that
//  fires a single `onDismiss` callback when the Tutors sheet goes
//  away, regardless of how it was dismissed (tap on a tutor, swipe
//  to dismiss, tap outside, etc.).
//
//  Why a singleton: `presentTutorsSheet` creates a fresh
//  `UINavigationController` each time, so we can't store the
//  delegate on the view controller itself. A shared observer lets
//  every present get its dismissal broadcast through a stable hook.
//

import UIKit

final class TutorsSheetObserver: NSObject, UIAdaptivePresentationControllerDelegate {
    static let shared = TutorsSheetObserver()

    /// Set by the view controller before present; cleared after
    /// firing. Use a closure here so the VC doesn't have to conform
    /// to a separate protocol just to listen.
    var onDismiss: (() -> Void)?

    private override init() { super.init() }

    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        let cb = onDismiss
        onDismiss = nil
        cb?()
    }
}
