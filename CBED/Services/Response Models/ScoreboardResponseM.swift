import Foundation

struct ScoreboardResponseM: Codable {
    let babyBarJune: [ScoreM]
    let babyBarOct: [ScoreM]
    let proBarFeb: [ScoreM]
    let proBarJuly: [ScoreM]
    /// Email & Zoom cohort. Exposed by the backend under key `email_zoom`
    /// (see `/api/scoreboard-111`). Excluded from member-plan buckets
    /// server-side, so no risk of duplication.
    let emailZoom: [ScoreM]
    let tutor: [ScoreM]

    enum CodingKeys: String, CodingKey {
        case babyBarJune = "baby_bar_june"
        case babyBarOct = "baby_bar_oct"
        case proBarFeb = "pro_bar_feb"
        case proBarJuly = "pro_bar_july"
        case emailZoom = "email_zoom"
        case tutor = "tutor"
    }
}

struct ScoreM: Codable {
    let id: Int
    let name: String?
    let avatar: String?
    let points: Int
    let lastSectionName: String?
    let essaysCount: Int
    let mptCount: Int
    var isEssay: Bool = false
    var isMpt: Bool = false
    /// The text the leaderboard row's right-side label should show for this
    /// entry under the active section filter. Populated by the scoreboard
    /// view model in `applySectionFilter(_:to:)` based on the active chip.
    /// Optional: cells fall back to `lastSectionName` when this is nil.
    /// Decoded from the wire as nil; set in code only.
    var displayText: String? = nil

    // Per-section FK ids, exposed by `/api/scoreboard-111`. Each is the
    // user's currently-assigned section in that NextGen module (e.g.
    // 50004 = IQS Drafting Set 04). Optional because old clients don't
    // emit them, and because some users haven't started that module yet.
    let currentDraftingSectionId: Int?
    let currentCounselingSectionId: Int?
    let currentNgSptSectionId: Int?
    let currentNgLrptSectionId: Int?
    let currentNgMcq1ChoiceSectionId: Int?
    let currentNgMcq2ChoiceSectionId: Int?

    // Resolved section names (e.g. "Drafting Set 04", "Level 1 - 1 Choice MCQ").
    // Returned by the backend as `current_<section>_name`; the backend
    // resolves the FK on the server side so the iOS view model can render
    // the exact curriculum title under each NextGen chip instead of
    // falling back to the user's MBE level title.
    let currentDraftingSectionName: String?
    let currentCounselingSectionName: String?
    let currentNgSptSectionName: String?
    let currentNgLrptSectionName: String?
    let currentNgMcq1ChoiceSectionName: String?
    let currentNgMcq2ChoiceSectionName: String?

    /// True when this user is in the Email & Zoom cohort (Vanessa only,
    /// currently). Mirrors the backend's `is_email_zoom` serializer alias
    /// (`source="is_tutor"` on the user model). Used by Settings to decide
    /// whether to expose the Email & Zoom count editor.
    let isEmailZoom: Bool

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case avatar = "avatar"
        case points = "points"
        case lastSectionName = "last_section_name"
        case essaysCount = "essay_count"
        case mptCount = "mpt_count"
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
        case isEmailZoom = "is_email_zoom"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(Int.self, forKey: .id)
        name = try c.decodeIfPresent(String.self, forKey: .name)
        avatar = try c.decodeIfPresent(String.self, forKey: .avatar)
        points = try c.decode(Int.self, forKey: .points)
        lastSectionName = try c.decodeIfPresent(String.self, forKey: .lastSectionName)
        essaysCount = (try? c.decode(Int.self, forKey: .essaysCount)) ?? 0
        mptCount = (try? c.decode(Int.self, forKey: .mptCount)) ?? 0
        currentDraftingSectionId = try c.decodeIfPresent(Int.self, forKey: .currentDraftingSectionId)
        currentCounselingSectionId = try c.decodeIfPresent(Int.self, forKey: .currentCounselingSectionId)
        currentNgSptSectionId = try c.decodeIfPresent(Int.self, forKey: .currentNgSptSectionId)
        currentNgLrptSectionId = try c.decodeIfPresent(Int.self, forKey: .currentNgLrptSectionId)
        currentNgMcq1ChoiceSectionId = try c.decodeIfPresent(Int.self, forKey: .currentNgMcq1ChoiceSectionId)
        currentNgMcq2ChoiceSectionId = try c.decodeIfPresent(Int.self, forKey: .currentNgMcq2ChoiceSectionId)
        currentDraftingSectionName = try c.decodeIfPresent(String.self, forKey: .currentDraftingSectionName)
        currentCounselingSectionName = try c.decodeIfPresent(String.self, forKey: .currentCounselingSectionName)
        currentNgSptSectionName = try c.decodeIfPresent(String.self, forKey: .currentNgSptSectionName)
        currentNgLrptSectionName = try c.decodeIfPresent(String.self, forKey: .currentNgLrptSectionName)
        currentNgMcq1ChoiceSectionName = try c.decodeIfPresent(String.self, forKey: .currentNgMcq1ChoiceSectionName)
        currentNgMcq2ChoiceSectionName = try c.decodeIfPresent(String.self, forKey: .currentNgMcq2ChoiceSectionName)
        isEmailZoom = (try? c.decode(Bool.self, forKey: .isEmailZoom)) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(name, forKey: .name)
        try c.encodeIfPresent(avatar, forKey: .avatar)
        try c.encode(points, forKey: .points)
        try c.encodeIfPresent(lastSectionName, forKey: .lastSectionName)
        try c.encode(essaysCount, forKey: .essaysCount)
        try c.encode(mptCount, forKey: .mptCount)
        try c.encodeIfPresent(currentDraftingSectionId, forKey: .currentDraftingSectionId)
        try c.encodeIfPresent(currentCounselingSectionId, forKey: .currentCounselingSectionId)
        try c.encodeIfPresent(currentNgSptSectionId, forKey: .currentNgSptSectionId)
        try c.encodeIfPresent(currentNgLrptSectionId, forKey: .currentNgLrptSectionId)
        try c.encodeIfPresent(currentNgMcq1ChoiceSectionId, forKey: .currentNgMcq1ChoiceSectionId)
        try c.encodeIfPresent(currentNgMcq2ChoiceSectionId, forKey: .currentNgMcq2ChoiceSectionId)
        try c.encodeIfPresent(currentDraftingSectionName, forKey: .currentDraftingSectionName)
        try c.encodeIfPresent(currentCounselingSectionName, forKey: .currentCounselingSectionName)
        try c.encodeIfPresent(currentNgSptSectionName, forKey: .currentNgSptSectionName)
        try c.encodeIfPresent(currentNgLrptSectionName, forKey: .currentNgLrptSectionName)
        try c.encodeIfPresent(currentNgMcq1ChoiceSectionName, forKey: .currentNgMcq1ChoiceSectionName)
        try c.encodeIfPresent(currentNgMcq2ChoiceSectionName, forKey: .currentNgMcq2ChoiceSectionName)
        try c.encode(isEmailZoom, forKey: .isEmailZoom)
    }
}
