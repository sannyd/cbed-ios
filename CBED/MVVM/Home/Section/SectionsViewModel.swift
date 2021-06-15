//
//  SectionViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import RxSwift
import RxCocoa
import RxSwiftExt

// MARK: Input + Output
extension SectionsViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
    }
    
    struct Output {
        let sections: Driver<[CommonCollectionViewSection<SectionM>]>
        let navigationTitle: Driver<String>
    }
}

struct SectionsViewModel: ViewModel {
    let useCase: SectionsUseCaseType
    let navigator: SectionsNavigatorType
    let levelID: Int
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let fetchLevelDetail = input
            .firstLoadTrigger
            .flatMapLatest(fetchSectionsByLevelID)
            .share(replay: 1)
        
        let sections = fetchLevelDetail
            .map (\.sections)
            .unwrap()
            .map { [CommonCollectionViewSection(items: $0)] }
            .asDriver(onErrorJustReturn: [])
        
        let navigationTitle = fetchLevelDetail
            .map(\.name)
            .unwrap()
            .asDriverOnErrorJustComplete()
        
        return Output(sections: sections,
                      navigationTitle: navigationTitle)
    }
    
    private func fetchSectionsByLevelID() -> Observable<LevelDetailM> {
        return self.useCase
            .getLevelByID(levelID)
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
