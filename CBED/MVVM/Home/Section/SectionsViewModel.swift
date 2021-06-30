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
        let loadMoreTrigger: Observable<Void>
        let sectionTapped: Observable<SectionM>
    }
    
    struct Output {
        let sections: Observable<[CommonCollectionViewSection<SearchResultM>]>
        let navigationTitle: Observable<String>
        let lastPageInvoked: Observable<Void>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct SectionsViewModel: ViewModel {
    let useCase: SectionsUseCaseType
    let navigator: SectionsNavigatorType
    let levelID: Int
    let levelTitle: String
    private let offset = 40
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        var nextPage: String = ""
        let lastPageTrigger = PublishSubject<Void>()
        
        var section = CommonCollectionViewSection<SearchResultM>(items: [])
        
        let fetchLevelDetail = input
            .firstLoadTrigger
            .map { _ in offset }
            .flatMapLatest(fetchSectionsByLevelID)
            .do(onNext: { response in
                nextPage = response.next ?? ""
                section.items = response.results
            })
            .map { _ in [section] }
//            .share(replay: 1)
        
        let loadMoreItems = input
            .loadMoreTrigger
            .map { _ in getOffsetFromURL(nextPage) }
            .unwrap()
            .flatMapLatest(fetchSectionsByLevelID)
            .do(onNext: { response in
                nextPage = response.next ?? ""
                section.items = response.results
            })
            .map { _ in [section] }
        
        let sections = Observable.merge(fetchLevelDetail,
                                    loadMoreItems)
        
        input
            .sectionTapped
            .map { SectionInfo(sectionID: $0.id, levelTitle: $0.name ?? "") }
            .subscribe(onNext: navigator.pushToSectionDetailVC(sectionInfo:))
            .disposed(by: disposeBag)
        
        return Output(sections: sections,
                      navigationTitle: .just(levelTitle),
                      lastPageInvoked: lastPageTrigger.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    private func getOffsetFromURL(_ urlString: String) -> Int? {
        guard let components = URLComponents(string: urlString),
              let offset = components.queryItems?.first(where: { $0.name == "offset" })?.value,
              let offsetNumber = Int(offset) else {
            return nil
        }
        
        return offsetNumber
    }
    
    private func fetchSectionsByLevelID(offset: Int) -> Observable<SectionSearchResponseM> {
        return self.useCase
            .searchSection(keySearch: "", limit: offset, offset: offset)
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
