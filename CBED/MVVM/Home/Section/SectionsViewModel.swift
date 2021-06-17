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
        let sectionTapped: Observable<SectionM>
    }
    
    struct Output {
        let sections: Driver<[CommonCollectionViewSection<SectionM>]>
        let navigationTitle: Driver<String>
        let isLoading: Driver<Bool>
        let error: Driver<Error>
    }
}

struct SectionsViewModel: ViewModel {
    let useCase: SectionsUseCaseType
    let navigator: SectionsNavigatorType
    let levelID: Int
    let levelTitle: String
    
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
        
        input
            .sectionTapped
            .map { SectionInfo(sectionID: $0.id, levelTitle: $0.name ?? "") }
            .subscribe(onNext: navigator.pushToSectionDetailVC(sectionInfo:))
            .disposed(by: disposeBag)
        
        return Output(sections: sections,
                      navigationTitle: .just(levelTitle),
                      isLoading: activityIndicator.asDriver(),
                      error: errorTracker.asDriver())
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
