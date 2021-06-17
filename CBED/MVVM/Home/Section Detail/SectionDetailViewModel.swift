//
//  SectionDetailViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import RxSwift
import RxCocoa

enum UsefulLinkType {
    case video
    case pdf
}

struct UsefulLink: Equatable {
    let type: UsefulLinkType
    let url: String
}

// MARK: Input + Output
extension SectionDetailViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let usefulLinkTapped: Observable<UsefulLink>
    }
    
    struct Output {
        let sectionInfo: Driver<SectionInfo>
        let usefulLinks: Driver<[CommonCollectionViewSection<UsefulLink>]>
        let isLoading: Driver<Bool>
        let error: Driver<Error>
    }
}

struct SectionInfo {
    let sectionID: Int
    let levelTitle: String
}

struct SectionDetailViewModel: ViewModel {
    let useCase: SectionDetailUseCaseType
    let navigator: SectionDetailNavigatorType
    let sectionInfo: SectionInfo
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let sectionDetail = input
            .firstLoadTrigger
            .flatMapLatest(fetchSectionDetail)
            .share(replay: 1)
        
        let youtubes = sectionDetail
            .map(\.youtubeUrls)
            .unwrap()
            .map { $0.map { UsefulLink(type: .pdf, url: $0) } }
        
        let pdfs = sectionDetail
            .map(\.pdfUrls)
            .unwrap()
            .map { $0.map { UsefulLink(type: .pdf, url: $0) } }
        
        let usefulLinks = Observable.combineLatest(youtubes,
                                                   pdfs)
            .map { $0 + $1 }
            .map { [CommonCollectionViewSection(items: $0)] }
            .asDriver(onErrorJustReturn: [])
        
        input
            .usefulLinkTapped
            .map(\.url)
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToPreviewWebView(usefulLinkURL:))
            .disposed(by: disposeBag)
        
        return Output(sectionInfo: .just(sectionInfo),
                      usefulLinks: usefulLinks,
                      isLoading: activityIndicator.asDriver(),
                      error: errorTracker.asDriver())
    }
    
    private func fetchSectionDetail() -> Observable<SectionDetailM> {
        return self.useCase
            .getSectionByID(id: sectionInfo.sectionID)
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
