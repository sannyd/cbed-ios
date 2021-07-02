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

struct SearchViewModel: ViewModel {
    let useCase: SearchUseCaseType
    let navigator: SearchNavigatorType
    
    private let offset = 10
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        
    }
}
