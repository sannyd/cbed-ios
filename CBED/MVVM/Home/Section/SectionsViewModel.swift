//
//  SectionViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import RxSwift
import RxCocoa
import RxSwiftExt

protocol LoadMoreViewModel: ViewModel {
    associatedtype T: PagingResponse
    
    var lastPageTrigger: PublishSubject<Void> { get }
    var isLoadMore: BehaviorRelay<Bool> { get }
    var isReload: BehaviorRelay<Bool> { get }
    var isLastPagination: BehaviorRelay<Bool> { get }
    var nextPage: BehaviorRelay<String> { get }
    var errorTracker: ErrorTracker { get }
    var activityIndicator: ActivityIndicator { get }
    
    func getNextPage(offset: Int,
                     searchText: String) -> Observable<T>
    
    func getPage(nextPageRequest: Observable<Void>,
                 offset: Int,
                 searchText: Observable<String>) -> Observable<T>
    
    func reload(reloadTrigger: Observable<Void>,
                searchText: Observable<String>,
                offset: Int) -> Observable<T>
}

extension LoadMoreViewModel {
    func getPage(nextPageRequest: Observable<Void>,
                 offset: Int,
                 searchText: Observable<String>) -> Observable<T> {
        let nextPageRequest = activityIndicator
            .asObservable()
            .sample(nextPageRequest)
        
        let isLoadMoreValid = Observable.combineLatest(nextPageRequest,
                                                       isLoadMore,
                                                       isReload)
            { !$0 && !$1 && !$2 }
        
        let result = nextPageRequest
            .withLatestFrom(isLoadMoreValid)
            .filter { $0 }
            .withLatestFrom(Observable.combineLatest(searchText,
                                                     nextPage))
            .subscribe(on: MainScheduler.instance)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMap { searchText, nextPage -> Observable<T> in
                guard !isLoadMore.value && !isReload.value else {
                    return .never()
                }
                
                guard let offset = getOffsetFromURL(nextPage) else {
                    isLoadMore.accept(false)
                    isLastPagination.accept(true)
                    return .never()
                }
                
                isLoadMore.accept(true)
                return self.getNextPage(offset: offset,
                                        searchText: searchText)
                    .catch { _ in
                        isLoadMore.accept(false)
                        return .never()
                    }
            }
            .do(onNext: { response in
                isLoadMore.accept(false)
                nextPage.accept(response.next ?? "")
            })
        
        return result
    }
    
    func reload(reloadTrigger: Observable<Void>,
                searchText: Observable<String>,
                offset: Int) -> Observable<T> {
        return reloadTrigger
            .do(onNext: { _ in
                isReload.accept(true)
            })
            .withLatestFrom(searchText)
            .subscribe(on: MainScheduler.instance)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapLatest { searchText in
                getNextPage(offset: offset,
                            searchText: searchText)
            }
            .do(onNext: { response in
                nextPage.accept(response.next ?? "")
                isReload.accept(false)
                isLastPagination.accept(false)
            })
    }
    
    private func getOffsetFromURL(_ urlString: String) -> Int? {
        guard let components = URLComponents(string: urlString),
              let offset = components.queryItems?.first(where: { $0.name == "offset" })?.value,
              let offsetNumber = Int(offset) else {
            return nil
        }
        
        return offsetNumber
    }
}

// MARK: Input + Output
extension SectionsViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let loadMoreTrigger: Observable<Void>
        let sectionTapped: Observable<SearchResultM>
    }
    
    struct Output {
        let sections: Observable<[CommonCollectionViewSection<SearchResultM>]>
        let navigationTitle: Observable<String>
        let lastPageInvoked: Observable<Void>
        let isLoading: Observable<Bool>
        let isLoadMore: Observable<Bool>
        let isLastPagination: Observable<Bool>
        let error: Observable<Error>
    }
}

struct SectionsViewModel: LoadMoreViewModel {
    typealias T = SectionSearchResponseM
    
    let lastPageTrigger = PublishSubject<Void>()
    let isLoadMore = BehaviorRelay<Bool>(value: false)
    let isReload = BehaviorRelay<Bool>(value: false)
    let isLastPagination = BehaviorRelay<Bool>(value: false)
    let nextPage = BehaviorRelay<String>(value: "")
    
    let useCase: SectionsUseCaseType
    let navigator: SectionsNavigatorType
    let levelID: Int
    let levelTitle: String
    private let offset = 10
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let sections = BehaviorRelay<[CommonCollectionViewSection<SearchResultM>]>(value: [])
        
        reload(reloadTrigger: input.firstLoadTrigger,
               searchText: .just(""),
               offset: offset)
            .map { [CommonCollectionViewSection(items: $0.results)] }
            .observe(on: MainScheduler.instance)
            .bind(to: sections)
            .disposed(by: disposeBag)
        
        getPage(nextPageRequest: input.loadMoreTrigger,
                offset: offset,
                searchText: .just(""))
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
            .map { SectionInfo(sectionID: $0.id, levelTitle: $0.name ?? "") }
            .subscribe(onNext: navigator.pushToSectionDetailVC(sectionInfo:))
            .disposed(by: disposeBag)
        
        return Output(sections: sections.asObservable(),
                      navigationTitle: .just(levelTitle),
                      lastPageInvoked: lastPageTrigger.asObservable(),
                      isLoading: isReload.asObservable(),
                      isLoadMore: isLoadMore.asObservable(),
                      isLastPagination: isLastPagination.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    func getNextPage(offset: Int,
                     searchText: String) -> Observable<SectionSearchResponseM> {
        //        return .deferred {
        return self.useCase
            .searchSection(request: .init(search: searchText,
                                          level: "\(levelID)",
                                          limit: self.offset,
                                          offset: offset))
            .trackActivity(activityIndicator)
            .trackError(errorTracker)
        //        }
    }
}
