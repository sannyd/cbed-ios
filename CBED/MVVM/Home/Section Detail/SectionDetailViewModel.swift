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
        let buttonStartTrigger: Observable<Int?>
        let buttonOutlineTrigger: Observable<Void>
    }
    
    struct Output {
        let sectionDetail: Driver<(String?, SectionDetailM)>
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
    let sectionDetail: SectionDetailM
    let imageURL: String?
    let level: LevelM
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
//        let sectionDetail = input
//            .firstLoadTrigger
//            .flatMapLatest(fetchSectionDetail)
//            .share(replay: 1)
        
        let youtubes = Observable
            .just(sectionDetail)
            .map(\.youtubeUrls)
            .unwrap()
            .filter { $0.allSatisfy { !$0.isEmpty } }
            .map { $0.map { UsefulLink(type: .video, url: $0) } }
        
        let pdfs = Observable
            .just(sectionDetail)
            .map(\.pdfUrls)
            .unwrap()
            .filter { $0.allSatisfy { !$0.isEmpty } }
            .map { $0.map { UsefulLink(type: .pdf, url: $0) } }
        
        let usefulLinks = Observable.combineLatest(youtubes,
                                                   pdfs)
            .map { $0 + $1 }
            .map { [CommonCollectionViewSection(items: $0)] }
            .asDriver(onErrorJustReturn: [])
        
        input
            .usefulLinkTapped
            .map(\.url)
            .map { url in
                let strings = url.split(separator: ",")
                
                return String(strings.last ?? "")
            }
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToPreviewWebView(usefulLinkURL:))
            .disposed(by: disposeBag)
        
        input
            .buttonStartTrigger
            .map { timerMinutes in (sectionDetail, level, timerMinutes) }
            .asDriverOnErrorJustComplete()
            .drive(onNext: { payload in
                navigator.pushToExamVC(sectionDetail: payload.0,
                                       level: payload.1,
                                       customTimeLimitMinutes: payload.2)
            })
            .disposed(by: disposeBag)
        
        input
            .buttonOutlineTrigger
            .map { _ in (sectionDetail, level) }
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToOutline(sectionDetail:level:))
            .disposed(by: disposeBag)
        
        return Output(sectionDetail: .just((imageURL, sectionDetail)),
                      usefulLinks: usefulLinks,
                      isLoading: activityIndicator.asDriver(),
                      error: errorTracker.asDriver())
    }
    
//    private func fetchSectionDetail() -> Observable<SectionDetailM> {
//        return self.useCase
//            .getSectionByID(id: sectionInfo.sectionID)
//            .trackError(errorTracker)
//            .trackActivity(activityIndicator)
//            .catch { _ in
//                return .never()
//            }
//    }
}
