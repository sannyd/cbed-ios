import Foundation

struct UpdateProfileRequestM: BaseRequestM, Encodable {
    let name: String?
    let state: String?
    let phone: String?
    let essayCount: Int?
    let mptCount: Int?
    
    init(name: String? = nil, state: String? = nil, phone: String? = nil, essayCount: Int? = nil, mptCount: Int? = nil) {
        self.name = name
        self.state = state
        self.phone = phone
        self.essayCount = essayCount
        self.mptCount = mptCount
    }
    
    enum CodingKeys: String, CodingKey {
        case name, state
        case phone = "phone_number"
        case essayCount = "essay_count"
        case mptCount = "mpt_count"
    }
}
