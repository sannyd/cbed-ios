//
//  AppIconManager.swift
//  CBED
//

import UIKit

final class AppIconManager {
    static let shared = AppIconManager()

    private init() {}

    func applyTestingMode(isEnabled: Bool) {
        if isEnabled {
            Storage.lastOpenedAt = Calendar.current.date(byAdding: .day, value: -1, to: Date())
            updateIconForCurrentInactivity()
        } else {
            Storage.lastOpenedAt = Date()
            applyIcon(named: nil)
        }
    }

    func updateIconForCurrentInactivity() {
        guard UIApplication.shared.supportsAlternateIcons else {
            return
        }

        applyIcon(named: alternateIconName(for: inactiveDays()))
    }

    private func inactiveDays() -> Int {
        guard let lastOpenedAt = Storage.lastOpenedAt else {
            return 0
        }

        let calendar = Calendar.current
        let startOfLastOpen = calendar.startOfDay(for: lastOpenedAt)
        let startOfToday = calendar.startOfDay(for: Date())
        return max(calendar.dateComponents([.day], from: startOfLastOpen, to: startOfToday).day ?? 0, 0)
    }

    private func alternateIconName(for inactiveDays: Int) -> String? {
        switch inactiveDays {
        case 7...:
            return "AppIconInactive7"
        case 3...:
            return "AppIconInactive3"
        case 1...:
            return "AppIconInactive1"
        default:
            return nil
        }
    }

    private func applyIcon(named iconName: String?) {
        guard UIApplication.shared.alternateIconName != iconName else {
            return
        }

        UIApplication.shared.setAlternateIconName(iconName) { error in
            if let error {
                Log.e(error.localizedDescription)
            }
        }
    }
}
