//
//  Storage.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 2/25/21.
//

import Foundation
import KeychainSwift

enum StorageKey: String {
    case accessToken
    case refreshToken
    case profileInfo
    case isEnableFaceID
    case faceIDExpireDate
    case examLocation
    case currentLevel
}

enum StorageType {
    case userDefault
    case keychain
}

protocol StorageProtocol {
    static func set(value: Data?, forKey key: String, storageType type: StorageType)
    static func get(key: String, storageType type: StorageType) -> Data?
    static func remove(key: String, storageType type: StorageType)
    static func removeAll()
}

struct Storage: StorageProtocol {
    static func set(value: Data?, forKey key: String, storageType type: StorageType) {
        guard let value = value else {
            return
        }
        switch type {
        case .userDefault:
            UserDefaults.standard.set(value, forKey: key)
        case .keychain:
            KeychainSwift().set(value, forKey: key)
        }
    }
    
    static func get(key: String, storageType type: StorageType) -> Data? {
        switch type {
        case .userDefault:
            return UserDefaults.standard.value(forKey: key) as? Data
        case .keychain:
            return KeychainSwift().getData(key)
        }
    }
    
    static func remove(key: String, storageType type: StorageType) {
        switch type {
        case .userDefault:
            UserDefaults.standard.setValue(nil, forKey: key)
        case .keychain:
            KeychainSwift().delete(key)
        }
    }
    
    static func removeAll() {
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
