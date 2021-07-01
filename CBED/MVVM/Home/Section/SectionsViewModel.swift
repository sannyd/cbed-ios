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
        let isLoadMore: Observable<Bool>
        let error: Observable<Error>
    }
}

struct SectionsViewModel: ViewModel {
    let useCase: SectionsUseCaseType
    let navigator: SectionsNavigatorType
    let levelID: Int
    let levelTitle: String
    private let offset = 10
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        var nextPage: String = ""
        let lastPageTrigger = PublishSubject<Void>()
        let isLoadMore = BehaviorRelay<Bool>(value: false)
        let isReload = BehaviorRelay<Bool>(value: false)
        let isLastPagination = BehaviorRelay<Bool>(value: true)
        let sections = BehaviorRelay<[CommonCollectionViewSection<SearchResultM>]>(value: [])
        
        input
            .firstLoadTrigger
            .do(onNext: { _ in
                isReload.accept(true)
            })
            .map { _ in offset }
            .subscribe(on: MainScheduler.instance)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMapLatest(fetchSectionsByLevelID)
            .do(onNext: { response in
                nextPage = response.next ?? ""
                isReload.accept(false)
                isLastPagination.accept(false)
            })
            .map { [CommonCollectionViewSection(items: $0.results)] }
            .observe(on: MainScheduler.instance)
            .bind(to: sections)
            .disposed(by: disposeBag)
        
        let nextPageRequest = activityIndicator
            .asObservable()
            .sample(input.loadMoreTrigger)
      
        nextPageRequest
            .map { isLoading in (isLoading: isLoading, offset: getOffsetFromURL(nextPage)) }
            .subscribe(on: MainScheduler.instance)
            .observe(on: ConcurrentDispatchQueueScheduler(qos: .background))
            .flatMap { (isLoading, offset) -> Observable<SectionSearchResponseM> in
                guard !isLoading else {
                    return .never()
                }
                guard !isLoadMore.value && !isReload.value else {
                    return .never()
                }
                
                guard let offset = offset else {
                    defer {
                        isLoadMore.accept(false)
                        isLastPagination.accept(true)
                    }
                    return .never()
                }
                
//                defer {
                    isLoadMore.accept(true)
//                }
                
                return self.fetchSectionsByLevelID(offset: offset)
                    .catch { _ in
                        isLoadMore.accept(false)
                        return .never()
                    }
            }
            .do(onNext: { response in
                nextPage = response.next ?? ""
                isLoadMore.accept(false)
            })
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
                      isLoading: activityIndicator.asObservable(),
                      isLoadMore: isLoadMore.asObservable(),
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
            .searchSection(request: .init(search: "", level: "\(levelID)", limit: self.offset, offset: offset))
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
    }
}
