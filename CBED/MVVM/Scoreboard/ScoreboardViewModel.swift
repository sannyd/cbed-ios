import RxSwift
import RxCocoa

// MARK: - Filter enums

enum ExamCycle {
    case july
    case feb
    case babyBarJun
    case babyBarOct
}

enum SectionFilter {
    case all
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
        case .all:           return "All"
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
}

// MARK: - Input + Output

extension ScoreboardViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let viewWillAppear: Observable<Void>
        let examCycleTrigger: Observable<ExamCycle>
        let sectionFilterTrigger: Observable<SectionFilter>
        let tutorsTrigger: Observable<Void>
    }

    struct Output {
        let data: Observable<[CommonCollectionViewSection<ScoreM>]>
        let userProfile: Observable<ProfileInfoM?>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
        let tutorsTrigger: Observable<[ScoreM]>
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

        let examCycle = BehaviorRelay<ExamCycle>(value: .july)
        let sectionFilter = BehaviorRelay<SectionFilter>(value: .all)

        input.examCycleTrigger
            .bind(to: examCycle)
            .disposed(by: disposeBag)

        input.sectionFilterTrigger
            .bind(to: sectionFilter)
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
                tutorsRelay.accept(response.tutor)
            })
            .disposed(by: disposeBag)

        // Combine cohort × section filter into the displayed list.
        let data = Observable
            .combineLatest(examCycle, sectionFilter)
            .map { cycle, filter -> [ScoreM] in
                let cohort: [ScoreM]
                switch cycle {
                case .july:        cohort = proBarJulData.value
                case .feb:         cohort = proBarFebData.value
                case .babyBarJun:  cohort = babyBarJunData.value
                case .babyBarOct:  cohort = babyBarOctData.value
                }
                return applySectionFilter(filter, to: cohort)
            }
            .map { [CommonCollectionViewSection(items: $0)] }

        // Fire tutorsTrigger each time the user taps the Tutors button.
        let tutorsTriggerStream = input.tutorsTrigger
            .withLatestFrom(tutorsRelay)

        return Output(
            data: data,
            userProfile: userProfile.asObservable(),
            isLoading: activityIndicator.asObservable(),
            error: errorTracker.asObservable(),
            tutorsTrigger: tutorsTriggerStream
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
        case .all:
            // Make sure no stale `displayText` from a prior filter shows
            // up when the user reverts to `.all`. Reset & return.
            return cohort.map { score -> ScoreM in
                var copy = score
                copy.isEssay = false
                copy.isMpt = false
                copy.displayText = nil
                return copy
            }
        case .mbe:
            // MBE section: the scoring API returns `lastSectionName` like
            // "Level 7 - Property", which is exactly the user's MBE level.
            // Annotate as "MBE: Level 7 - Property" so it's clear which
            // filter is in effect.
            return cohort.filter { ($0.lastSectionName ?? "").contains("Level") }
                .map { score -> ScoreM in
                    var copy = score
                    copy.isEssay = false
                    copy.isMpt = false
                    let level = score.lastSectionName ?? "N/A"
                    copy.displayText = "MBE: \(level)"
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
        case .ng1Choice,
             .ng2Choice,
             .iqsCounseling,
             .iqsDrafting,
             .spt,
             .lrpt:
            // The current API response doesn't expose per-section drill
            // counts for NextGen modules per-user. To still give the user
            // useful visual feedback when a NextGen chip is selected, we
            // annotate each row with the active filter name and the
            // user's last-section-name (the only data we have). Once the
            // backend exposes per-section drill counts, swap this for a
            // proper field-by-field lookup.
            return cohort
                .map { score -> ScoreM in
                    var copy = score
                    copy.isEssay = false
                    copy.isMpt = false
                    let level = score.lastSectionName ?? "Not started"
                    copy.displayText = "\(filter.label): \(level)"
                    return copy
                }
        }
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
            tutor: []
        )
    }
}
