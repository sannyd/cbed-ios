//
//  Storage+.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 2/25/21.
//

import Foundation

extension Storage {
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
}
