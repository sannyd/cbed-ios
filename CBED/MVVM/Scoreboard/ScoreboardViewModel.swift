//
//  ScoreboardViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension ScoreboardViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let viewWillAppear: Observable<Void>
        let filterTrigger: Observable<InAppPurchaseMonth>
    }
    
    struct Output {
        let data: Observable<[CommonCollectionViewSection<ScoreM>]>
        let filterInvoked: Observable<InAppPurchaseMonth>
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
        let data = BehaviorRelay<[ScoreM]>(value: [])
        let filterTrigger = BehaviorRelay<InAppPurchaseMonth>(value: .ProBarFeb)
        
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
                
                switch filterTrigger.value {
                case .ProBarFeb:
                    data.accept(proBarFebData)
                case .ProBarJul:
                    data.accept(proBarJulData)
                case .BabyBarJun:
                    data.accept(babyBarJunData)
                case .BabyBarOct:
                    data.accept(babyBarOctData)
                }
                
            })
            .disposed(by: disposeBag)
        
        sharedFilterTrigger
            .map { filterType in
                switch filterType {
                case .ProBarFeb:
                    return proBarFebData
                case .ProBarJul:
                    return proBarJulData
                case .BabyBarJun:
                    return babyBarJunData
                case .BabyBarOct:
                    return babyBarOctData
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
