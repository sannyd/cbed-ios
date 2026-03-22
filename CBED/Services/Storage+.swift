//
//  Storage+.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 2/25/21.
//

import Foundation
import UIKit

enum AppTheme: Int, CaseIterable {
    case system
    case light
    case dark
    
    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system:
            return .unspecified
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}

extension Storage {
    static var appTheme: AppTheme {
        get {
            guard let rawValue = UserDefaults.standard.object(forKey: StorageKey.appTheme.rawValue) as? Int,
                  let theme = AppTheme(rawValue: rawValue) else {
                return .system
            }
            return theme
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: StorageKey.appTheme.rawValue)
        }
    }
    
    static var isEnableFaceID: Bool {
        get {
            if UserDefaults.standard.object(forKey: StorageKey.isEnableFaceID.rawValue) == nil {
                return false
            } else {
                return UserDefaults.standard.bool(forKey: StorageKey.isEnableFaceID.rawValue)
            }
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: StorageKey.isEnableFaceID.rawValue)
        }
    }

    static var isButtonSoundEnabled: Bool {
        get {
            if UserDefaults.standard.object(forKey: StorageKey.isButtonSoundEnabled.rawValue) == nil {
                return true
            } else {
                return UserDefaults.standard.bool(forKey: StorageKey.isButtonSoundEnabled.rawValue)
            }
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: StorageKey.isButtonSoundEnabled.rawValue)
        }
    }

    static var isNotificationTestingEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: StorageKey.isNotificationTestingEnabled.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: StorageKey.isNotificationTestingEnabled.rawValue)
        }
    }

    static var isAppIconTestingEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: StorageKey.isAppIconTestingEnabled.rawValue)
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: StorageKey.isAppIconTestingEnabled.rawValue)
        }
    }

    static var faceIDExpireDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: StorageKey.faceIDExpireDate.rawValue) as? Date
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: StorageKey.faceIDExpireDate.rawValue)
        }
    }

    static var lastOpenedAt: Date? {
        get {
            return UserDefaults.standard.object(forKey: StorageKey.lastOpenedAt.rawValue) as? Date
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: StorageKey.lastOpenedAt.rawValue)
        }
    }
    
    static var accessToken: String? {
        get {
            guard let data = Storage.get(key: StorageKey.accessToken.rawValue, storageType: .userDefault),
                  let valueString = String(data: data, encoding: .utf8) else {
                return nil
            }
            return valueString
        }
        set {
            guard let data = newValue?.data(using: .utf8, allowLossyConversion: false) else {
                return
            }
            Storage.set(value: data, forKey: StorageKey.accessToken.rawValue, storageType: .userDefault)
        }
    }
    
    static var currentLevel: String? {
        get {
            guard let data = UserDefaults(suiteName: "group.com.cbed.share")?.data(forKey: StorageKey.currentLevel.rawValue),
                  let valueString = String(data: data, encoding: .utf8) else {
                return nil
            }
            return valueString
        }
        set {
            guard let data = newValue?.data(using: .utf8, allowLossyConversion: false) else {
                return
            }
            UserDefaults(suiteName: "group.com.cbed.share")?.set(data, forKey: StorageKey.currentLevel.rawValue)
        }
    }
    
    static var refreshToken: String? {
        get {
            guard let data = Storage.get(key: StorageKey.refreshToken.rawValue, storageType: .userDefault),
                  let valueString = String(data: data, encoding: .utf8) else {
                return nil
            }
            return valueString
        }
        set {
            guard let data = newValue?.data(using: .utf8, allowLossyConversion: false) else {
                return
            }
            Storage.set(value: data, forKey: StorageKey.refreshToken.rawValue, storageType: .userDefault)
        }
    }
    
    static var examLocation: ExamLocation {
        get {
            guard let data = Storage.get(key: StorageKey.examLocation.rawValue, storageType: .userDefault),
                  let valueString = String(data: data, encoding: .utf8),
                  let location = ExamLocation(rawValue: valueString) else {
                return .mpre
            }
            return location
        }
        set {
            guard let data = newValue.rawValue.data(using: .utf8, allowLossyConversion: false) else {
                return
            }
            Storage.set(value: data, forKey: StorageKey.examLocation.rawValue, storageType: .userDefault)
        }
    }
    
    static var profileInfo: ProfileInfoM? {
        get {
            let userDefaults = UserDefaults.standard
            do {
                let user = try userDefaults.getObject(forKey: StorageKey.profileInfo.rawValue, castTo: ProfileInfoM.self)
                return user
            } catch {
                print(error.localizedDescription)
            }
            return nil
        }
        set {
            let userDefaults = UserDefaults.standard
            do {
                try userDefaults.setObject(newValue, forKey: StorageKey.profileInfo.rawValue)
            } catch {
                Log.e(error.localizedDescription)
            }
        }
    }

    static var notificationSchedule: NotificationScheduler.ScheduleSettings? {
        get {
            let userDefaults = UserDefaults.standard
            do {
                return try userDefaults.getObject(forKey: StorageKey.notificationSchedule.rawValue,
                                                  castTo: NotificationScheduler.ScheduleSettings.self)
            } catch {
                return nil
            }
        }
        set {
            let userDefaults = UserDefaults.standard
            do {
                try userDefaults.setObject(newValue, forKey: StorageKey.notificationSchedule.rawValue)
            } catch {
                Log.e(error.localizedDescription)
            }
        }
    }
}
