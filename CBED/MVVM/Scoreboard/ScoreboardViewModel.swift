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
        
        let sharedFilterTrigger = input.filterTrigger.share(replay: 1)
        
        let userProfile = input
            .viewWillAppear
            .map { _ in Storage.profileInfo }
        
        input
            .firstLoadTrigger
            .flatMapLatest(fetchScoreboard)
            .subscribe(onNext: { response in
                proBarFebData = response.proBarFeb
                proBarJulData = response.proBarJuly
                babyBarJunData = response.babyBarJune
                babyBarOctData = response.babyBarOct
                data.accept(proBarFebData)
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
