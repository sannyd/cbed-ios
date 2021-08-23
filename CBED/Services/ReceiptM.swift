//
//  ReceiptM.swift
//  CBED
//
//  Created by Jimmy Hoang on 8/22/21.
//

import Foundation

struct ReceiptM: Codable {
    let receipt: ReceiptResponseM?
}

// MARK: - Welcome
struct ReceiptResponseM: Codable {
    let adamID: Int?
    let appItemID: Int?
    let applicationVersion: Int?
    let bundleID: String?
    let downloadID: Int?
    let inApp: [InApp]?
    let originalApplicationVersion: String?
    let originalPurchaseDate: String?
    let originalPurchaseDateMS: Int?
    let originalPurchaseDatePst: String?
    let receiptCreationDate: String?
    let receiptCreationDateMS: Int?
    let receiptCreationDatePst: String?
    let receiptType: String?
    let requestDate: String?
    let requestDateMS: Int?
    let requestDatePst: String?
    let versionExternalIdentifier: Int?

    enum CodingKeys: String, CodingKey {
        case adamID = "adam_id"
        case appItemID = "app_item_id"
        case applicationVersion = "application_version"
        case bundleID = "bundle_id"
        case downloadID = "download_id"
        case inApp = "in_app"
        case originalApplicationVersion = "original_application_version"
        case originalPurchaseDate = "original_purchase_date"
        case originalPurchaseDateMS = "original_purchase_date_ms"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case receiptCreationDate = "receipt_creation_date"
        case receiptCreationDateMS = "receipt_creation_date_ms"
        case receiptCreationDatePst = "receipt_creation_date_pst"
        case receiptType = "receipt_type"
        case requestDate = "request_date"
        case requestDateMS = "request_date_ms"
        case requestDatePst = "request_date_pst"
        case versionExternalIdentifier = "version_external_identifier"
    }
}

// MARK: - InApp
struct InApp: Codable {
    let inAppOwnershipType: String?
    let isTrialPeriod: Bool?
    let originalPurchaseDate: String?
    let originalPurchaseDateMS: Int?
    let originalPurchaseDatePst: String?
    let originalTransactionID: Int?
    let productID: String?
    let purchaseDate: String?
    let purchaseDateMS: Int?
    let purchaseDatePst: String?
    let quantity: Int?
    let transactionID: Int?

    enum CodingKeys: String, CodingKey {
        case inAppOwnershipType = "in_app_ownership_type"
        case isTrialPeriod = "is_trial_period"
        case originalPurchaseDate = "original_purchase_date"
        case originalPurchaseDateMS = "original_purchase_date_ms"
        case originalPurchaseDatePst = "original_purchase_date_pst"
        case originalTransactionID = "original_transaction_id"
        case productID = "product_id"
        case purchaseDate = "purchase_date"
        case purchaseDateMS = "purchase_date_ms"
        case purchaseDatePst = "purchase_date_pst"
        case quantity = "quantity"
        case transactionID = "transaction_id"
    }
}
