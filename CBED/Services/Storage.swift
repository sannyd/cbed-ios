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
    case availableDriver
}

enum StorageType {
    case userDefault
    case keychain
}

protocol StorageProtocol {
    static func set(value: Data?, forKey key: StorageKey, storageType type: StorageType)
    static func get(key: StorageKey, storageType type: StorageType) -> Data?
    static func remove(key: StorageKey, storageType type: StorageType)
    static func removeAll()
}

struct Storage: StorageProtocol {
    static func set(value: Data?, forKey key: StorageKey, storageType type: StorageType) {
        guard let value = value else {
            return
        }
        switch type {
        case .userDefault:
            UserDefaults.standard.set(value, forKey: key.rawValue)
        case .keychain:
            KeychainSwift().set(value, forKey: key.rawValue)
        }
    }
    
    static func get(key: StorageKey, storageType type: StorageType) -> Data? {
        switch type {
        case .userDefault:
            return UserDefaults.standard.value(forKey: key.rawValue) as? Data
        case .keychain:
            return KeychainSwift().getData(key.rawValue)
        }
    }
    
    static func remove(key: StorageKey, storageType type: StorageType) {
        switch type {
        case .userDefault:
            UserDefaults.standard.setValue(nil, forKey: key.rawValue)
        case .keychain:
            KeychainSwift().delete(key.rawValue)
        }
    }
    
    static func removeAll() {
        let dictionary = UserDefaults.standard.dictionaryRepresentation()
        dictionary.keys.forEach { key in
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}
