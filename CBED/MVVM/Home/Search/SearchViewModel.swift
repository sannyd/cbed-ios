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
    private let nextGenSearchLevelID = 8
    private let georgiaSearchLevelID = 14
    private let nextGenChildLevelIDs = [29, 30, 31, 33, 34, 35]
    private let nextGenEssayLevelIDs: Set<Int> = [31, 33, 34, 35]
    private let largeSearchLimit = 1000
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    let loadingIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let sections = BehaviorRelay<[CommonCollectionViewSection<SearchResultM>]>(value: [])
        let isNextGenSearch = level.id == nextGenSearchLevelID
        
        let normalizedSearchText = input
            .searchText
            .map(normalizeSearchText)
        let sharedInputSearchText = (isNextGenSearch
                                     ? normalizedSearchText.startWith("")
                                     : normalizedSearchText)
            .distinctUntilChanged()
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
                searchText: sharedInputSearchText)
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
        guard level.id == nextGenSearchLevelID else {
            if level.id == georgiaSearchLevelID {
                return searchGeorgiaEssays(searchText: searchText)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
            }

            return self.useCase
                .searchEssay(request: .init(search: searchText,
                                            level: "\(level.id)",
                                            limit: self.offset,
                                            offset: offset))
                .trackActivity(activityIndicator)
                .trackError(errorTracker)
        }
        
        return Single
            .zip(nextGenChildLevelIDs.map { fetchNextGenLevelResults(levelID: $0,
                                                                     searchText: searchText) })
            .flatMap { responses in
                let mergedResults = mergeNextGenResults(from: responses)
                let normalizedSearchText = normalizeSearchText(searchText)
                
                guard !normalizedSearchText.isEmpty else {
                    return .just(makeNextGenSearchResponse(results: mergedResults))
                }
                
                return Single
                    .zip(self.nextGenChildLevelIDs.map(self.fetchAllNextGenLevelResults))
                    .flatMap { allResponses in
                        let allResults = self.mergeNextGenResults(from: allResponses)
                        return self.searchNextGenSectionContents(results: allResults,
                                                                 searchText: normalizedSearchText)
                            .map { contentMatches in
                                let combinedResults = self.combineNextGenSearchResults(primary: mergedResults,
                                                                                      secondary: contentMatches)
                                return self.makeNextGenSearchResponse(results: combinedResults)
                            }
                    }
            }
            .asObservable()
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
    
    private func normalizeSearchText(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func fetchNextGenLevelResults(levelID: Int,
                                          searchText: String) -> Single<SectionSearchResponseM> {
        let request = SearchSectionRequestM(search: searchText,
                                            level: "\(levelID)",
                                            limit: largeSearchLimit,
                                            offset: 0)
        
        if nextGenEssayLevelIDs.contains(levelID) {
            return self.useCase.searchEssay(request: request)
        }
        
        return self.useCase.searchSection(request: request)
    }
    
    private func fetchAllNextGenLevelResults(levelID: Int) -> Single<SectionSearchResponseM> {
        self.useCase.searchSection(request: .init(search: "",
                                                  level: "\(levelID)",
                                                  limit: largeSearchLimit,
                                                  offset: 0))
    }

    private func searchGeorgiaEssays(searchText: String) -> Observable<SectionSearchResponseM> {
        let levelID = "\(georgiaSearchLevelID)"
        let directSearch = useCase.searchEssay(request: .init(search: searchText,
                                                              level: levelID,
                                                              limit: largeSearchLimit,
                                                              offset: 0))
        let allEssays = useCase.searchEssay(request: .init(search: "",
                                                           level: levelID,
                                                           limit: largeSearchLimit,
                                                           offset: 0))

        return Single.zip(directSearch, allEssays)
            .map { directResponse, allResponse in
                let localMatches = self.filterEssayResults(allResponse.results, using: searchText)
                let combinedResults = self.combineEssaySearchResults(primary: directResponse.results,
                                                                    secondary: localMatches)
                return SectionSearchResponseM(count: combinedResults.count,
                                              next: nil,
                                              previous: nil,
                                              results: combinedResults)
            }
            .asObservable()
    }
    
    private func mergeNextGenResults(from responses: [SectionSearchResponseM]) -> [SearchResultM] {
        responses.flatMap { response in
            response.results.sorted {
                let leftOrder = $0.order ?? .max
                let rightOrder = $1.order ?? .max
                
                if leftOrder != rightOrder {
                    return leftOrder < rightOrder
                }
                
                return $0.id < $1.id
            }
        }
    }
    
    private func makeNextGenSearchResponse(results: [SearchResultM]) -> SectionSearchResponseM {
        SectionSearchResponseM(count: results.count,
                               next: nil,
                               previous: nil,
                               results: results)
    }
    
    private func combineNextGenSearchResults(primary: [SearchResultM],
                                             secondary: [SearchResultM]) -> [SearchResultM] {
        var seenIDs = Set<Int>()
        let orderedResults = primary + secondary
        
        return orderedResults.filter { result in
            seenIDs.insert(result.id).inserted
        }
    }
    
    private func searchNextGenSectionContents(results: [SearchResultM],
                                              searchText: String) -> Single<[SearchResultM]> {
        Observable
            .from(results)
            .flatMap { result in
                self.useCase
                    .getSectionByID(id: result.id)
                    .asObservable()
                    .map { detail -> SearchResultM? in
                        self.matchesNextGenContent(searchText: searchText,
                                                   result: result,
                                                   detail: detail)
                            ? result
                            : nil
                    }
                    .catchAndReturn(nil)
            }
            .compactMap { $0 }
            .toArray()
    }
    
    private func matchesNextGenContent(searchText: String,
                                       result: SearchResultM,
                                       detail: SectionDetailM) -> Bool {
        let searchableText = [
            result.name,
            result.subtitle,
            result.levelName,
            detail.name
        ]
        + (detail.questions ?? []).flatMap { question in
            [question.content] + (question.answers ?? []).map(\.content)
        }
        
        return searchableText
            .compactMap { $0 }
            .contains { $0.localizedCaseInsensitiveContains(searchText) }
    }
    
    private func filterNextGenResults(_ results: [SearchResultM],
                                      using searchText: String) -> [SearchResultM] {
        let normalizedSearchText = normalizeSearchText(searchText)
        guard !normalizedSearchText.isEmpty else {
            return results
        }
        
        return results.filter { result in
            [result.name, result.subtitle, result.levelName]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(normalizedSearchText) }
        }
    }

    private func filterEssayResults(_ results: [SearchResultM],
                                    using searchText: String) -> [SearchResultM] {
        let normalizedSearchText = normalizeSearchText(searchText)
        guard !normalizedSearchText.isEmpty else {
            return results
        }

        return results.filter { result in
            [result.name, result.subtitle, result.levelName]
                .compactMap { $0 }
                .contains { $0.localizedCaseInsensitiveContains(normalizedSearchText) }
        }
    }

    private func combineEssaySearchResults(primary: [SearchResultM],
                                           secondary: [SearchResultM]) -> [SearchResultM] {
        var seenIDs = Set<Int>()

        return (primary + secondary).filter { result in
            seenIDs.insert(result.id).inserted
        }
    }
}
