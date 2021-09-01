//
//  ProfileInfoM.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/07/2021.
//

import Foundation

enum MemberPlan: String, Codable {    
    case free = "free"
    case proBarFeb = "com.barexamdrills.app.probarfeb"
    case proBarJul = "com.barexamdrills.app.probarjuly"
    case babybarJun = "com.barexamdrills.app.babybarjune"
    case babybarOct = "com.barexamdrills.app.babybaroct"
    
    var stringValue: String {
        switch self {
        case .free:
            return "Free"
        case .proBarFeb:
            return "Pro Bar - February"
        case .proBarJul:
            return "Pro Bar - July"
        case .babybarJun:
            return "Baby Bar - June"
        case .babybarOct:
            return "Baby Bar - Octobor"
        }
    }
}

struct ProfileInfoM: Codable {
    let email: String
    let avatar: String?
    let name: String
    let state: String
    let memberPlan: MemberPlan
    let memberPlanSimple: Int
    let membership: String
    let lastSectionName: String?
    let points: Int
    let phone: String?
    
    enum CodingKeys: String, CodingKey {
        case email = "email"
        case avatar = "avatar"
        case name = "name"
        case state = "state"
        case memberPlan = "member_plan"
        case memberPlanSimple = "member_plan_simple"
        case membership = "membership"
        case lastSectionName = "last_section_name"
        case points = "points"
        case phone = "phone_number"
    }
}
