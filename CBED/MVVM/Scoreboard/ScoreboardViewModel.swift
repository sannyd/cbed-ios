import RxSwift
import RxCocoa

// MARK: - Filter enums

/// Exam cycle / member-plan tab at the top of the scoreboard. The five
/// segments in the storyboard map to the cases here. As of V11.1 the
/// leftmost (and default-selected) chip is Email & Zoom; the visual
/// order in the storyboard is now:
///   .emailZoom   - leftmost (segment index 0, default-selected)
///   .july        - segment index 1
///   .feb         - segment index 2
///   .babyBarJun  - segment index 3
///   .babyBarOct  - segment index 4
enum ExamCycle {
    case july
    case feb
    case babyBarJun
    case babyBarOct
    case emailZoom
}

/// Within-cohort subject filter. The chips scroll horizontally below the
/// exam-cycle segmented control. The previously-shipped `.all` case has
/// been removed; `.mbe` is now the default (left-most chip after the
/// legacy "All" was deleted).
enum SectionFilter {
    case mbe
    case essays
    case mpt
    case ng1Choice
    case ng2Choice
    case iqsCounseling
    case iqsDrafting
    case spt
    case lrpt

    /// Human-readable label, used both as the row prefix shown after a
    /// chip selection and as a debugging tag. Matches the title set in
    /// the storyboard's chip button so the labels don't drift.
    var label: String {
        switch self {
        case .mbe:           return "MBE"
        case .essays:        return "Essays"
        case .mpt:           return "M/PTs"
        case .ng1Choice:     return "NG 1-Choice"
        case .ng2Choice:     return "NG 2-Choice"
        case .iqsCounseling: return "IQS Counseling"
        case .iqsDrafting:   return "IQS Drafting"
        case .spt:           return "SPT"
        case .lrpt:          return "LRPT"
        }
    }

    /// V11.1: chips that only make sense for students enrolled in the
    /// grading services (Email & Zoom package or Tutors-managed cohort).
    /// These chips are HIDDEN from the section chip row when the active
    /// exam cycle is a standard one (July / Feb / Baby Bar Jun / Oct)
    /// because general students don't have essays/MPTs graded and the
    /// leaderboard rows would all show count = 0.
    var isGradingOnly: Bool {
        switch self {
        case .essays, .mpt: return true
        default:            return false
        }
    }
}

// MARK: - Input + Output

extension ScoreboardViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let viewWillAppear: Observable<Void>
        let examCycleTrigger: Observable<ExamCycle>
        let sectionFilterTrigger: Observable<SectionFilter>
        let tutorsTrigger: Observable<Void>
        /// V11.1: emitted `true` when the Tutors sheet is presented and
        /// `false` when it is dismissed. Drives whether the Essays and
        /// M/PTs grading-only chips are visible in the section chip row.
        let tutorsSheetVisibility: Observable<Bool>
    }

    struct Output {
        let data: Observable<[CommonCollectionViewSection<ScoreM>]>
        let userProfile: Observable<ProfileInfoM?>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
        let tutorsTrigger: Observable<[ScoreM]>
        /// V11.1: ordered list of SectionFilter cases that should be
        /// visible in the section chip row for the current
        /// (examCycle, tutorsVisibility) tuple. The ViewController
        /// iterates this list to show/hide chips and to scroll the
        /// active chip into view.
        let availableSections: Observable<[SectionFilter]>
        /// V11.1: the currently-active section filter. Reflects the
        /// sectionFilter BehaviorRelay, which is auto-reset to MBE
        /// when the active filter becomes grading-only during a cycle
        /// change. The ViewController subscribes to keep the chip row
        /// styling in sync even when the reset happens internally.
        let selectedSection: Observable<SectionFilter>
    }
}

struct ScoreboardViewModel: ViewModel {
    let useCase: ScoreboardUseCaseType
    let navigator: ScoreboardNavigatorType

    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()

    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        // The API returns five cohorts. Tutors are exposed via Output.tutorsTrigger
        // (independent of any filter selection) so the Tutors sheet can show them
        // regardless of which exam cycle / section the user is currently viewing.
        //
        // The "data" output is driven by (examCycle × sectionFilter):
        //   - examCycle picks which cohort (proBarJul / proBarFeb / babyBarJun / babyBarOct)
        //   - sectionFilter picks the within-cohort slice (mbé / essays / mpt / all / NextGen)

        let proBarJulData = BehaviorRelay<[ScoreM]>(value: [])
        let proBarFebData = BehaviorRelay<[ScoreM]>(value: [])
        let babyBarJunData = BehaviorRelay<[ScoreM]>(value: [])
        let babyBarOctData = BehaviorRelay<[ScoreM]>(value: [])
        // New in V11.1: Email & Zoom cohort. Excluded from member-plan
        // buckets server-side, so no risk of duplication. The Tutors modal
        // pulls its data from `tutorsRelay` below, which is a separate
        // cohort entirely (`is_tutor_for_bed=True`).
        let emailZoomData = BehaviorRelay<[ScoreM]>(value: [])

        // Default to `.emailZoom` — the spec asks for Email & Zoom to
        // be the first chip and the default-selected cycle on launch.
        // Both relays start at the same default so neither view nor
        // view-model has to special-case the initial render.
        let examCycle = BehaviorRelay<ExamCycle>(value: .emailZoom)
        // Default to MBE now that `.all` is gone — the user explicitly asked
        // for "the first selected chip must default to MBE".
        let sectionFilter = BehaviorRelay<SectionFilter>(value: .mbe)
        // V11.1: whether the Tutors sheet is currently presented. Drives
        // whether grading-only chips (Essays, M/PTs) are visible.
        let isTutorsSheetVisible = BehaviorRelay<Bool>(value: false)

        input.examCycleTrigger
            .bind(to: examCycle)
            .disposed(by: disposeBag)

        input.sectionFilterTrigger
            .bind(to: sectionFilter)
            .disposed(by: disposeBag)

        input.tutorsSheetVisibility
            .bind(to: isTutorsSheetVisible)
            .disposed(by: disposeBag)

        let userProfile = input
            .viewWillAppear
            .map { _ in Storage.profileInfo }

        let tutorsRelay = BehaviorRelay<[ScoreM]>(value: [])

        input.firstLoadTrigger
            .flatMapLatest { [useCase] _ in
                useCase.getScoreboard()
                    .trackError(errorTracker)
                    .trackActivity(activityIndicator)
                    .catchAndReturn(ScoreboardResponseM.empty)
            }
            .subscribe(onNext: { response in
                proBarJulData.accept(response.proBarJuly.sorted(by: sectionSort))
                proBarFebData.accept(response.proBarFeb.sorted(by: sectionSort))
                babyBarJunData.accept(response.babyBarJune.sorted(by: sectionSort))
                babyBarOctData.accept(response.babyBarOct.sorted(by: sectionSort))
                emailZoomData.accept(response.emailZoom)
                tutorsRelay.accept(response.tutor)
            })
            .disposed(by: disposeBag)

        // Combine cohort × section filter into the displayed list.
        //
        // V11.1 critical fix: the cohort relays (proBarJulData,
        // proBarFebData, babyBarJunData, babyBarOctData, emailZoomData)
        // MUST be included as combineLatest sources — otherwise the
        // data stream never re-emits when the API response populates
        // them on first launch. The closure that maps `cycle` →
        // `cohort.value` only runs when `combineLatest` fires; if the
        // cohort relays aren't observed, an updated cohort is read
        // inside the closure but `combineLatest` never re-runs the
        // closure, so the collection view stays empty until the user
        // triggers a cycle / section chip change.
        let data = Observable
            .combineLatest(
                examCycle,
                sectionFilter,
                proBarJulData,
                proBarFebData,
                babyBarJunData,
                babyBarOctData,
                emailZoomData
            )
            .map { cycle, filter, jul, feb, bbj, bbo, ez -> [ScoreM] in
                let cohort: [ScoreM]
                switch cycle {
                case .july:        cohort = jul
                case .feb:         cohort = feb
                case .babyBarJun:  cohort = bbj
                case .babyBarOct:  cohort = bbo
                case .emailZoom:   cohort = ez
                }
                return applySectionFilter(filter, to: cohort)
            }
            .map { [CommonCollectionViewSection(items: $0)] }

        // V11.1: derive the ordered list of section chips that should be
        // visible given the active exam cycle + Tutors sheet visibility.
        // The Tutors sheet is treated as "eligible for grading" — when
        // it's up, the Essays / M/PTs chips become visible so a Tutors
        // user can pivot to grading filters while reviewing a student.
        //
        // V11.1.1: Baby Bar candidates (Jun / Oct) only get access to
        // MBE drills — they don't take the NextGen curriculum and don't
        // get Essays / M/PTs graded by tutors. So when the active cycle
        // is either Baby Bar bucket, only the MBE chip is exposed.
        let availableSections = Observable
            .combineLatest(examCycle, isTutorsSheetVisible)
            .map { cycle, tutorsVisible -> [SectionFilter] in
                if cycle == .babyBarJun || cycle == .babyBarOct {
                    return [.mbe]
                }
                if cycle == .emailZoom || tutorsVisible {
                    return [.mbe, .essays, .mpt, .ng1Choice, .ng2Choice,
                            .iqsDrafting, .iqsCounseling, .spt, .lrpt]
                }
                return [.mbe, .ng1Choice, .ng2Choice,
                        .iqsDrafting, .iqsCounseling, .spt, .lrpt]
            }
            .distinctUntilChanged { $0.map { $0.label } == $1.map { $0.label } }

        // V11.1: if the user is on a grading-only chip (Essays / M/PTs)
        // and then switches to a standard exam cycle, auto-reset back
        // to MBE so the data stream doesn't filter by an invisible chip.
        //
        // V11.1.1: also auto-reset to MBE when the user lands on either
        // Baby Bar cycle, since those only expose MBE. Without this guard,
        // tapping "Baby Bar Jun" while sitting on, say, ".ng1Choice" would
        // briefly leave the row empty (data stream filters by a hidden
        // chip and the UI shows no active chip). With the reset, the
        // row immediately renders MBE-active.
        Observable
            .combineLatest(examCycle, isTutorsSheetVisible, sectionFilter)
            .subscribe(onNext: { cycle, tutorsVisible, filter in
                let isBabyBar = (cycle == .babyBarJun || cycle == .babyBarOct)
                if isBabyBar && filter != .mbe {
                    sectionFilter.accept(.mbe)
                    return
                }
                let eligible = (cycle == .emailZoom) || tutorsVisible
                if !eligible && filter.isGradingOnly {
                    sectionFilter.accept(.mbe)
                }
            })
            .disposed(by: disposeBag)

        // Fire tutorsTrigger each time the user taps the Tutors button.
        let tutorsTriggerStream = input.tutorsTrigger
            .withLatestFrom(tutorsRelay)

        return Output(
            data: data,
            userProfile: userProfile.asObservable(),
            isLoading: activityIndicator.asObservable(),
            error: errorTracker.asObservable(),
            tutorsTrigger: tutorsTriggerStream,
            availableSections: availableSections,
            selectedSection: sectionFilter.asObservable()
        )
    }

    // MARK: - Helpers

    /// Place users with `lastSectionName` set at the top of the leaderboard.
    private let sectionSort: (ScoreM, ScoreM) -> Bool = { a, b in
        (a.lastSectionName != nil && b.lastSectionName == nil)
    }

    /// Apply a within-cohort SectionFilter. The API response only carries
    /// `lastSectionName` per user (e.g. "Level 7 - Property"), so a strict
    /// section-tag filter is approximate — we use it as a hint to scope
    /// the leaderboard view. With `.all`, the full cohort is returned.
    ///
    /// Each non-`.all` filter now also populates `ScoreM.displayText` so
    /// the cell can render the right-side label with a context prefix
    /// (e.g. "MBE: Level 7 - Property"). For `.all`, `displayText` stays
    /// nil and the cell falls back to `lastSectionName` with the level
    /// color helper — the original ship behavior.
    private func applySectionFilter(_ filter: SectionFilter, to cohort: [ScoreM]) -> [ScoreM] {
        switch filter {
        case .mbe:
            // MBE section: the scoring API returns `lastSectionName` like
            // "Level 7 - Property", which is exactly the user's MBE level.
            return cohort
                .map { score -> ScoreM in
                    var copy = score
                    copy.isEssay = false
                    copy.isMpt = false
                    // V11.1: prefix stripped — the chip itself already names
                    // the filter, so showing "MBE: Level 7 - Property" was
                    // redundant. Display only the level text.
                    copy.displayText = score.lastSectionName ?? "Not started"
                    return copy
                }
        case .essays:
            return cohort
                .map { score -> ScoreM in
                    var copy = score
                    copy.isEssay = true
                    copy.isMpt = false
                    copy.displayText = nil
                    return copy
                }
                .sorted { $0.essaysCount > $1.essaysCount }
        case .mpt:
            return cohort
                .map { score -> ScoreM in
                    var copy = score
                    copy.isEssay = false
                    copy.isMpt = true
                    copy.displayText = nil
                    return copy
                }
                .sorted { $0.mptCount > $1.mptCount }
        case .ng1Choice:
            // V11.1: backend now exposes the resolved Section.name via
            // `current_ng_mcq_1_choice_section_name` (e.g. "Level 1 - 1 Choice MCQ").
            // Prefer that so each row shows the actual NextGen curriculum
            // title instead of falling back to the user's MBE level.
            return cohort.map { score -> ScoreM in
                var copy = score
                copy.isEssay = false
                copy.isMpt = false
                copy.displayText = score.currentNgMcq1ChoiceSectionName
                    ?? score.lastSectionName
                    ?? "Not started"
                return copy
            }
        case .ng2Choice:
            return cohort.map { score -> ScoreM in
                var copy = score
                copy.isEssay = false
                copy.isMpt = false
                copy.displayText = score.currentNgMcq2ChoiceSectionName
                    ?? score.lastSectionName
                    ?? "Not started"
                return copy
            }
        case .iqsCounseling:
            return cohort.map { score -> ScoreM in
                var copy = score
                copy.isEssay = false
                copy.isMpt = false
                copy.displayText = score.currentCounselingSectionName
                    ?? score.lastSectionName
                    ?? "Not started"
                return copy
            }
        case .iqsDrafting:
            return cohort.map { score -> ScoreM in
                var copy = score
                copy.isEssay = false
                copy.isMpt = false
                copy.displayText = score.currentDraftingSectionName
                    ?? score.lastSectionName
                    ?? "Not started"
                return copy
            }
        case .spt:
            return cohort.map { score -> ScoreM in
                var copy = score
                copy.isEssay = false
                copy.isMpt = false
                copy.displayText = score.currentNgSptSectionName
                    ?? score.lastSectionName
                    ?? "Not started"
                return copy
            }
        case .lrpt:
            return cohort.map { score -> ScoreM in
                var copy = score
                copy.isEssay = false
                copy.isMpt = false
                copy.displayText = score.currentNgLrptSectionName
                    ?? score.lastSectionName
                    ?? "Not started"
                return copy
            }
        }
    }

    // V11.1: legacy local hint generator. The backend now resolves
    // section names directly (`current_<section>_name`), so this is
    // kept only as a defensive fallback for users whose FK row points
    // at a section the iOS app cannot otherwise name (shouldn't happen
    // in practice — Section.title and Section.name are populated).
    private static func nextGenSectionHint(for id: Int?, prefix: String) -> String? {
        guard let id = id else { return nil }
        let suffix = id % 100
        guard suffix >= 1 else { return nil }
        let padded = suffix < 10 ? "0\(suffix)" : "\(suffix)"
        return "\(prefix) \(padded)"
    }
}

// MARK: - Empty placeholder

extension ScoreboardResponseM {
    static var empty: ScoreboardResponseM {
        ScoreboardResponseM(
            babyBarJune: [],
            babyBarOct: [],
            proBarFeb: [],
            proBarJuly: [],
            emailZoom: [],
            tutor: []
        )
    }
}
