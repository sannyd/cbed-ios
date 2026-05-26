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

final class AppUpdateChecker {
    static let shared = AppUpdateChecker()

    private var isChecking = false
    private var hasPromptedThisLaunch = false
    private let lookupBaseURL = "https://itunes.apple.com/lookup"

    func checkForUpdateIfNeeded(presenter: UIViewController) {
        guard !isChecking, !hasPromptedThisLaunch else {
            return
        }

        guard let bundleID = Bundle.main.bundleIdentifier,
              let encodedBundleID = bundleID.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "\(lookupBaseURL)?bundleId=\(encodedBundleID)") else {
            return
        }

        isChecking = true
        URLSession.shared.dataTask(with: url) { [weak self, weak presenter] data, _, _ in
            guard let self else { return }
            defer { self.isChecking = false }

            guard let data,
                  let response = try? JSONDecoder().decode(AppStoreLookupResponse.self, from: data),
                  let appStoreApp = response.results.first,
                  self.isVersion(appStoreApp.version, newerThan: self.currentAppVersion) else {
                return
            }

            DispatchQueue.main.async {
                guard let presenter,
                      presenter.presentedViewController == nil,
                      self.hasPromptedThisLaunch == false else {
                    return
                }

                self.hasPromptedThisLaunch = true
                let alert = UIAlertController(title: "Update Available",
                                              message: "A newer version of Bar Exam Drills is available. Please update to get the latest fixes and content.",
                                              preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Later", style: .cancel))
                alert.addAction(UIAlertAction(title: "Update", style: .default) { _ in
                    guard let url = URL(string: appStoreApp.trackViewUrl) else {
                        return
                    }
                    UIApplication.shared.open(url)
                })
                presenter.present(alert, animated: true)
            }
        }.resume()
    }

    private var currentAppVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    private func isVersion(_ candidate: String, newerThan current: String) -> Bool {
        candidate.compare(current, options: .numeric) == .orderedDescending
    }
}

private struct AppStoreLookupResponse: Decodable {
    let results: [AppStoreLookupResult]
}

private struct AppStoreLookupResult: Decodable {
    let version: String
    let trackViewUrl: String
}
