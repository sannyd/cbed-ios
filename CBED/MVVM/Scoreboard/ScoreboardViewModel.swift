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
    private func applySectionFilter(_ filter: SectionFilter, to cohort: [ScoreM]) -> [ScoreM] {
        switch filter {
        case .all:
            return cohort
        case .mbe:
            return cohort.filter { ($0.lastSectionName ?? "").contains("Level") }
        case .essays:
            return cohort
                .map { score -> ScoreM in
                    var copy = score
                    copy.isEssay = true
                    return copy
                }
                .sorted { $0.essaysCount > $1.essaysCount }
        case .mpt:
            return cohort
                .map { score -> ScoreM in
                    var copy = score
                    copy.isMpt = true
                    return copy
                }
                .sorted { $0.mptCount > $1.mptCount }
        case .ng1Choice,
             .ng2Choice,
             .iqsCounseling,
             .iqsDrafting,
             .spt,
             .lrpt:
            // The current API response doesn't expose per-section drill counts
            // for NextGen modules. Until the API gains these fields, treat
            // NextGen filters as "show the cohort" — they remain selectable
            // so the UI is correct, and they'll start narrowing once the
            // backend exposes the right payload.
            return cohort
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
