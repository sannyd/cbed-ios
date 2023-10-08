//
//  Storage+.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 2/25/21.
//

import Foundation

extension Storage {
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
    
    static var faceIDExpireDate: Date? {
        get {
            return UserDefaults.standard.object(forKey: StorageKey.faceIDExpireDate.rawValue) as? Date
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: StorageKey.faceIDExpireDate.rawValue)
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
                return .ube
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
}
