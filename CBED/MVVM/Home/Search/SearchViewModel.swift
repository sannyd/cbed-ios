//
//  SearchViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 7/2/21.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension SearchViewModel {
    struct Input {
        let searchText: Observable<String>
        let firstLoadTrigger: Observable<Void>
        let loadMoreTrigger: Observable<Void>
        let sectionTapped: Observable<SearchResultM>
    }
    
    struct Output {
        let sections: Observable<[CommonCollectionViewSection<SearchResultM>]>
        let lastPageInvoked: Observable<Void>
        let isReloading: Observable<Bool>
        let isLoading: Observable<Bool>
        let isLoadMore: Observable<Bool>
        let isLastPagination: Observable<Bool>
        let error: Observable<Error>
    }
}

struct SearchViewModel: LoadMoreViewModel {
    typealias T = SectionSearchResponseM
    
    let lastPageTrigger = PublishSubject<Void>()
    let isLoadMore = BehaviorRelay<Bool>(value: false)
    let isReload = BehaviorRelay<Bool>(value: false)
    let isLastPagination = BehaviorRelay<Bool>(value: false)
    var nextPage = BehaviorRelay<String>(value: "")
    
    let useCase: SearchUseCaseType
    let navigator: SearchNavigatorType
    let level: LevelM
    
    private let offset = 10
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    let loadingIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let sections = BehaviorRelay<[CommonCollectionViewSection<SearchResultM>]>(value: [])
        
        let sharedInputSearchText = input
            .searchText
            .share(replay: 1)
        
        reload(reloadTrigger: sharedInputSearchText.mapToVoid(),
               searchText: sharedInputSearchText,
               offset: offset)
            .map { [CommonCollectionViewSection(items: $0.results)] }
            .observe(on: MainScheduler.instance)
            .bind(to: sections)
            .disposed(by: disposeBag)
        
        getPage(nextPageRequest: input.loadMoreTrigger,
                offset: offset,
                searchText: input.searchText)
            .map { response in
                var temp = sections.value.first
                var items = temp?.items ?? []
                items += response.results
                temp?.items = items
                
                return [temp].compactMap { $0 }
            }
            .observe(on: MainScheduler.instance)
            .bind(to: sections)
            .disposed(by: disposeBag)
        
        input
            .sectionTapped
            .flatMapLatest(fetchSectionDetailByID(searchResult:))
            .asDriverOnErrorJustComplete()
            .drive(onNext: { searchResult, sectionDetail in
                guard sectionDetail.isAvailable ?? true else {
                    navigator.showBlockSectionAlert()
                    return
                }
                
                if (sectionDetail.questions ?? []).isEmpty {
                    if let youtubeURL = sectionDetail.youtubeUrls?.first {
                        navigator.pushToPreviewWebView(usefulLinkURL: youtubeURL)
                    }
                    if let pdfURL = sectionDetail.pdfUrls?.first {
                        navigator.pushToPreviewWebView(usefulLinkURL: pdfURL)
                    }
                } else {
                    navigator.pushToSectionDetailVC(sectionDetail: sectionDetail, searchResult: searchResult, level: level)
                }
            })
            .disposed(by: disposeBag)
        
        return Output(sections: sections.asObservable(),
                      lastPageInvoked: lastPageTrigger.asObservable(),
                      isReloading: isReload.asObservable(),
                      isLoading: loadingIndicator.asObservable(),
                      isLoadMore: isLoadMore.asObservable(),
                      isLastPagination: isLastPagination.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    // Override
    func getNextPage(offset: Int,
                     searchText: String) -> Observable<SectionSearchResponseM> {
        return Observable.zip(fetchCAEssay(),
                       fetchMEEEssay())
        .map { (caEssays, meeEssays) in
            var results = caEssays.results + meeEssays.results
            results = results.filter { $0.name?.lowercased().contains(searchText.lowercased()) ?? false }
            
            let response = SectionSearchResponseM(count: 0, next: nil, previous: nil, results: results)
            
            return response
        }
    }
    
    
    func fetchMEEEssay() -> Observable<SectionSearchResponseM> {
        return self.useCase
            .searchSection(request: .init(search: "",
                                          level: "9",
                                          limit: 100,
                                          offset: offset))
            .trackActivity(activityIndicator)
            .trackError(errorTracker)
    }
    
    func fetchCAEssay() -> Observable<SectionSearchResponseM> {
        return self.useCase
            .searchSection(request: .init(search: "",
                                          level: "7",
                                          limit: 100,
                                          offset: offset))
            .trackActivity(activityIndicator)
            .trackError(errorTracker)
    }
    
    private func fetchSectionDetailByID(searchResult: SearchResultM) -> Observable<(SearchResultM, SectionDetailM)> {
        return self.useCase
            .getSectionByID(id: searchResult.id)
            .trackError(errorTracker)
            .trackActivity(loadingIndicator)
            .catch { _ in
                return .never()
            }
            .map { (searchResult, $0) }
    }
}
