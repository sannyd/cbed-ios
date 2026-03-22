import RxSwift
import RxCocoa

enum ScoreboardSection {
    case barExamFeb
    case barExamJuly
    case babyBar(BabyBarSection)
    case zoomEmail(ZoomEmailSection)
}

enum BabyBarSection {
    case june
    case october
}

enum ZoomEmailSection {
    case essays
    case mpt
    case mbe
}



// MARK: Input + Output
extension ScoreboardViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let viewWillAppear: Observable<Void>
        let filterTrigger: Observable<ScoreboardSection>
    }
    
    struct Output {
        let data: Observable<[CommonCollectionViewSection<ScoreM>]>
        let filterInvoked: Observable<ScoreboardSection>
        let userProfile: Observable<ProfileInfoM?>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct ScoreboardViewModel: ViewModel {
    let useCase: ScoreboardUseCaseType
    let navigator: ScoreboardNavigatorType
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        var proBarFebData: [ScoreM] = []
        var proBarJulData: [ScoreM] = []
        var babyBarJunData: [ScoreM] = []
        var babyBarOctData: [ScoreM] = []
        var essaysData: [ScoreM] = []
        var mptData: [ScoreM] = []
        var mbeData: [ScoreM] = []
        let data = BehaviorRelay<[ScoreM]>(value: [])
        let filterTrigger = BehaviorRelay<ScoreboardSection>(value: .barExamFeb)
        
        let sharedFilterTrigger = input.filterTrigger.share(replay: 1)
        sharedFilterTrigger
            .bind(to: filterTrigger)
            .disposed(by: disposeBag)
        
        let userProfile = input
            .viewWillAppear
            .map { _ in Storage.profileInfo }
        
        input
            .firstLoadTrigger
            .flatMapLatest(fetchScoreboard)
            .subscribe(onNext: { response in
                proBarFebData = response.proBarFeb.sorted(by: { score1, score2 in
                    score1.lastSectionName != nil && score2.lastSectionName == nil
                })
                proBarJulData = response.proBarJuly
                    .sorted(by: { score1, score2 in
                        score1.lastSectionName != nil && score2.lastSectionName == nil
                    })
                babyBarJunData = response.babyBarJune
                    .sorted(by: { score1, score2 in
                        score1.lastSectionName != nil && score2.lastSectionName == nil
                    })
                babyBarOctData = response.babyBarOct
                    .sorted(by: { score1, score2 in
                        score1.lastSectionName != nil && score2.lastSectionName == nil
                    })
                mbeData = response.tutor
                    .sorted(by: { score1, score2 in
                        score1.lastSectionName != nil && score2.lastSectionName == nil
                    })
                essaysData = response.tutor
                    .map { item in
                        var temp = item
                        temp.isEssay = true
                        
                        return temp
                    }
                    .sorted(by: { score1, score2 in
                        score1.essaysCount > score2.essaysCount
                    })
                mptData = response.tutor
                    .map { item in
                        var temp = item
                        temp.isMpt = true
                        
                        return temp
                    }
                    .sorted(by: { score1, score2 in
                        score1.mptCount > score2.mptCount
                    })

                switch filterTrigger.value {
                case .barExamFeb:
                    data.accept(proBarFebData)
                case .barExamJuly:
                    data.accept(proBarJulData)
                case .babyBar(let babyBarSection):
                    switch babyBarSection {
                    case .june:
                        data.accept(babyBarJunData)
                    case .october:
                        data.accept(babyBarOctData)
                    }
                case .zoomEmail(let zoomEmailSection):
                    switch zoomEmailSection {
                    case .essays:
                        data.accept(essaysData)
                    case .mpt:
                        data.accept(mptData)
                    case .mbe:
                        data.accept(mbeData)
                    }
                }
                
            })
            .disposed(by: disposeBag)

        sharedFilterTrigger
            .map { section in
                switch section {
                case .barExamFeb:
                    return proBarFebData
                case .barExamJuly:
                    return proBarJulData
                case .babyBar(let babyBarSection):
                    switch babyBarSection {
                    case .june:
                        return babyBarJunData
                    case .october:
                        return babyBarOctData
                    }
                case .zoomEmail(let zoomEmailSection):
                    switch zoomEmailSection {
                    case .essays:
                        return essaysData
                    case .mpt:
                        return mptData
                    case .mbe:
                        return mbeData
                    }
                }
            }
            .bind(to: data)
            .disposed(by: disposeBag)
        
        return Output(data: data.map { [CommonCollectionViewSection(items: $0)] }.asObservable(),
                      filterInvoked: sharedFilterTrigger.asObservable(),
                      userProfile: userProfile.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    private func fetchScoreboard() -> Observable<ScoreboardResponseM> {
        return useCase
            .getScoreboard()
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
