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
            return "No Membership"
        case .proBarFeb:
            return "Bar Exam - Feb"
        case .proBarJul:
            return "Bar Exam - July"
        case .babybarJun:
            return "Baby Bar - June"
        case .babybarOct:
            return "Baby Bar - Oct"
        }
    }
}

struct ProfileInfoM: Codable {
    let id: Int?
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
    let essayCount: Int
    let mptCount: Int
    let isTutor: Bool
    /// Email & Zoom cohort flag. Mirrors `is_tutor` on the user model
    /// (Vanessa is currently the only user with `is_tutor=True`). Used
    /// by Settings to decide whether to show the count editor.
    let isEmailZoom: Bool
    let currentMixedMbeSection: Int?
    let currentDraftingSectionId: Int?
    let currentCounselingSectionId: Int?
    let currentNgSptSectionId: Int?
    let currentNgLrptSectionId: Int?
    let currentNgMcq1ChoiceSectionId: Int?
    let currentNgMcq2ChoiceSectionId: Int?

    enum CodingKeys: String, CodingKey {
        case id = "id"
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
        case essayCount = "essay_count"
        case mptCount = "mpt_count"
        case isTutor = "is_tutor"
        case isEmailZoom = "is_email_zoom"
        case currentMixedMbeSection = "current_mixed_mbe_section"
        case currentDraftingSectionId = "current_drafting_section"
        case currentCounselingSectionId = "current_counseling_section"
        case currentNgSptSectionId = "current_ng_spt_section"
        case currentNgLrptSectionId = "current_ng_lrpt_section"
        case currentNgMcq1ChoiceSectionId = "current_ng_mcq_1_choice_section"
        case currentNgMcq2ChoiceSectionId = "current_ng_mcq_2_choice_section"
    }
}
