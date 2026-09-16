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
    // Resolved section names (mirror of the per-section FK ids above).
    // Returned by `/api/users/me` via the backend `UserInfoSerializer`,
    // resolved server-side from the related Section row. Currently used
    // by Settings to display the user's current IQS / NG module title.
    let currentDraftingSectionName: String?
    let currentCounselingSectionName: String?
    let currentNgSptSectionName: String?
    let currentNgLrptSectionName: String?
    let currentNgMcq1ChoiceSectionName: String?
    let currentNgMcq2ChoiceSectionName: String?

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
        case currentDraftingSectionName = "current_drafting_section_name"
        case currentCounselingSectionName = "current_counseling_section_name"
        case currentNgSptSectionName = "current_ng_spt_section_name"
        case currentNgLrptSectionName = "current_ng_lrpt_section_name"
        case currentNgMcq1ChoiceSectionName = "current_ng_mcq_1_choice_section_name"
        case currentNgMcq2ChoiceSectionName = "current_ng_mcq_2_choice_section_name"
    }

    /// Defensive decoder: every field uses `decodeIfPresent` so a missing
    /// or null field never crashes the JSON pipeline. This matters in
    /// practice because:
    /// - the Settings tab triggers a re-fetch of this struct
    /// - older or alternate endpoints may omit some fields
    /// - 3 fields (`isEmailZoom`, `essayCount`, `mptCount`) were added to
    ///   the wire and previously threw `DecodingError.keyNotFound` when
    ///   absent — that's the source of the Settings-tab fatal crash.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id          = try c.decodeIfPresent(Int.self,    forKey: .id)
        email       = (try c.decodeIfPresent(String.self, forKey: .email))    ?? ""
        avatar      = try c.decodeIfPresent(String.self, forKey: .avatar)
        name        = (try c.decodeIfPresent(String.self, forKey: .name))     ?? ""
        state       = (try c.decodeIfPresent(String.self, forKey: .state))    ?? ""
        // MemberPlan decoding: fall back to `.free` if the backend returns
        // a value we don't know (forward-compat for new membership SKUs).
        memberPlan  = (try c.decodeIfPresent(MemberPlan.self, forKey: .memberPlan)) ?? .free
        memberPlanSimple = (try c.decodeIfPresent(Int.self,    forKey: .memberPlanSimple)) ?? 0
        membership  = (try c.decodeIfPresent(String.self, forKey: .membership)) ?? ""
        lastSectionName = try c.decodeIfPresent(String.self, forKey: .lastSectionName)
        points      = (try c.decodeIfPresent(Int.self,     forKey: .points))  ?? 0
        phone       = try c.decodeIfPresent(String.self, forKey: .phone)
        essayCount  = (try c.decodeIfPresent(Int.self,     forKey: .essayCount))  ?? 0
        mptCount    = (try c.decodeIfPresent(Int.self,     forKey: .mptCount))    ?? 0
        isTutor     = (try c.decodeIfPresent(Bool.self,    forKey: .isTutor))     ?? false
        isEmailZoom = (try c.decodeIfPresent(Bool.self,    forKey: .isEmailZoom)) ?? false
        currentMixedMbeSection       = try c.decodeIfPresent(Int.self, forKey: .currentMixedMbeSection)
        currentDraftingSectionId     = try c.decodeIfPresent(Int.self, forKey: .currentDraftingSectionId)
        currentCounselingSectionId   = try c.decodeIfPresent(Int.self, forKey: .currentCounselingSectionId)
        currentNgSptSectionId        = try c.decodeIfPresent(Int.self, forKey: .currentNgSptSectionId)
        currentNgLrptSectionId       = try c.decodeIfPresent(Int.self, forKey: .currentNgLrptSectionId)
        currentNgMcq1ChoiceSectionId = try c.decodeIfPresent(Int.self, forKey: .currentNgMcq1ChoiceSectionId)
        currentNgMcq2ChoiceSectionId = try c.decodeIfPresent(Int.self, forKey: .currentNgMcq2ChoiceSectionId)
        currentDraftingSectionName       = try c.decodeIfPresent(String.self, forKey: .currentDraftingSectionName)
        currentCounselingSectionName     = try c.decodeIfPresent(String.self, forKey: .currentCounselingSectionName)
        currentNgSptSectionName          = try c.decodeIfPresent(String.self, forKey: .currentNgSptSectionName)
        currentNgLrptSectionName         = try c.decodeIfPresent(String.self, forKey: .currentNgLrptSectionName)
        currentNgMcq1ChoiceSectionName   = try c.decodeIfPresent(String.self, forKey: .currentNgMcq1ChoiceSectionName)
        currentNgMcq2ChoiceSectionName   = try c.decodeIfPresent(String.self, forKey: .currentNgMcq2ChoiceSectionName)
    }

    /// Convenience initializer for in-memory placeholders (used by
    /// `AppViewModel`'s fallback when profile info isn't loaded yet).
    init(id: Int? = nil,
         email: String = "",
         avatar: String? = nil,
         name: String = "",
         state: String = "",
         memberPlan: MemberPlan = .free,
         memberPlanSimple: Int = 0,
         membership: String = "",
         lastSectionName: String? = nil,
         points: Int = 0,
         phone: String? = nil,
         essayCount: Int = 0,
         mptCount: Int = 0,
         isTutor: Bool = false,
         isEmailZoom: Bool = false,
         currentMixedMbeSection: Int? = nil,
         currentDraftingSectionId: Int? = nil,
         currentCounselingSectionId: Int? = nil,
         currentNgSptSectionId: Int? = nil,
         currentNgLrptSectionId: Int? = nil,
         currentNgMcq1ChoiceSectionId: Int? = nil,
         currentNgMcq2ChoiceSectionId: Int? = nil,
         currentDraftingSectionName: String? = nil,
         currentCounselingSectionName: String? = nil,
         currentNgSptSectionName: String? = nil,
         currentNgLrptSectionName: String? = nil,
         currentNgMcq1ChoiceSectionName: String? = nil,
         currentNgMcq2ChoiceSectionName: String? = nil) {
        self.id = id
        self.email = email
        self.avatar = avatar
        self.name = name
        self.state = state
        self.memberPlan = memberPlan
        self.memberPlanSimple = memberPlanSimple
        self.membership = membership
        self.lastSectionName = lastSectionName
        self.points = points
        self.phone = phone
        self.essayCount = essayCount
        self.mptCount = mptCount
        self.isTutor = isTutor
        self.isEmailZoom = isEmailZoom
        self.currentMixedMbeSection = currentMixedMbeSection
        self.currentDraftingSectionId = currentDraftingSectionId
        self.currentCounselingSectionId = currentCounselingSectionId
        self.currentNgSptSectionId = currentNgSptSectionId
        self.currentNgLrptSectionId = currentNgLrptSectionId
        self.currentNgMcq1ChoiceSectionId = currentNgMcq1ChoiceSectionId
        self.currentNgMcq2ChoiceSectionId = currentNgMcq2ChoiceSectionId
        self.currentDraftingSectionName = currentDraftingSectionName
        self.currentCounselingSectionName = currentCounselingSectionName
        self.currentNgSptSectionName = currentNgSptSectionName
        self.currentNgLrptSectionName = currentNgLrptSectionName
        self.currentNgMcq1ChoiceSectionName = currentNgMcq1ChoiceSectionName
        self.currentNgMcq2ChoiceSectionName = currentNgMcq2ChoiceSectionName
    }
}
