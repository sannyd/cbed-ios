struct SubscriptionPlanM: Codable {
    let name: InAppPurchaseType
    let price: Double
    
    enum CodingKeys: String, CodingKey {
        case name
        case price
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(InAppPurchaseType.self, forKey: .name)
        let tempPrice = try container.decode(String.self, forKey: .price)
        
        price = Double(tempPrice) ?? 0
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(price, forKey: .price)
    }
}
