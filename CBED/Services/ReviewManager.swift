//
//  ReviewManager.swift
//  CBED
//
//  Created by Codex on 4/3/26.
//

import Foundation
import StoreKit
import UIKit

enum TortsMBELevel: String, CaseIterable {
    case level1
    case level3
    case level4

    fileprivate var promptedKey: String {
        "review_prompted_\(rawValue)"
    }
}

@MainActor
final class ReviewManager {
    static let shared = ReviewManager()

    private let userDefaults: UserDefaults
    private let appStoreAppID: String

    init(
        userDefaults: UserDefaults = .standard,
        appStoreAppID: String = "1234567890"
    ) {
        self.userDefaults = userDefaults
        self.appStoreAppID = appStoreAppID
    }

    func checkAndAskForReview(for level: TortsMBELevel, didPass: Bool) {
        guard didPass, hasPromptedForReview(at: level) == false else {
            return
        }

        guard let scene = reviewScene else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
        markPromptedForReview(at: level)
    }

    func openAppStorePage() {
        guard let url = URL(string: "itms-apps://itunes.apple.com/app/id\(appStoreAppID)?action=write-review") else {
            return
        }

        UIApplication.shared.open(url)
    }

    private func hasPromptedForReview(at level: TortsMBELevel) -> Bool {
        userDefaults.bool(forKey: level.promptedKey)
    }

    private func markPromptedForReview(at level: TortsMBELevel) {
        userDefaults.set(true, forKey: level.promptedKey)
    }

    private var reviewScene: UIWindowScene? {
        let connectedScenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let activeScene = connectedScenes.first(where: { $0.activationState == .foregroundActive && $0.keyWindow != nil }) {
            return activeScene
        }

        if let inactiveScene = connectedScenes.first(where: { $0.activationState == .foregroundInactive && $0.keyWindow != nil }) {
            return inactiveScene
        }

        return connectedScenes.first(where: { $0.keyWindow != nil })
            ?? connectedScenes.first(where: { $0.activationState == .foregroundActive })
            ?? connectedScenes.first
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? {
        windows.first(where: \.isKeyWindow)
    }
}
