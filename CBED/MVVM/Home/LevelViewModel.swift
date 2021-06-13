//
//  LevelViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension LevelViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let levelTapped: Observable<LevelM>
    }
    
    struct Output {
        let levels: Driver<[CommonCollectionViewSection<LevelM>]>
        let isLoading: Driver<Bool>
        let error: Driver<Error>
    }
}

struct LevelViewModel: ViewModel {
    let useCase: LevelUseCaseType
    let navigator: LevelNavigatorType
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let levels = input
            .firstLoadTrigger
            .flatMapLatest(fetchAllLevels)
            .map { [CommonCollectionViewSection(items: $0)] }
        
        return Output(levels: levels.asDriver(onErrorJustReturn: []),
                      isLoading: activityIndicator.asDriver(),
                      error: errorTracker.asDriver())
    }
    
    func fetchAllLevels() -> Observable<[LevelM]> {
        return self.useCase
            .getAllLevels()
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
    }
    
    func fetchLevelByID(_ id: String) -> Observable<LevelM> {
        return self.useCase
            .getLevelByID(id)
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
    }
}
