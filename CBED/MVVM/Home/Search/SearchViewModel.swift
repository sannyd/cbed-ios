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
    
    private let offset = 10
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
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
        
        return Output(sections: sections.asObservable(),
                      lastPageInvoked: lastPageTrigger.asObservable(),
                      isLoading: isReload.asObservable(),
                      isLoadMore: isLoadMore.asObservable(),
                      isLastPagination: isLastPagination.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    // Override
    func getNextPage(offset: Int,
                     searchText: String) -> Observable<SectionSearchResponseM> {
        return self.useCase
            .searchSection(request: .init(search: searchText,
                                          level: "9",
                                          limit: self.offset,
                                          offset: offset))
            .trackActivity(activityIndicator)
            .trackError(errorTracker)
    }
}
