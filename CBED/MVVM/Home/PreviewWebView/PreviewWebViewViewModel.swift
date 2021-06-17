//
//  PreviewWebViewViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 17/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension PreviewWebViewViewModel {
    struct Input {
        
    }
    
    struct Output {
        let usefulLinkURL: Driver<URL>
    }
}

struct PreviewWebViewViewModel: ViewModel {
    let useCase: PreviewWebViewUseCaseType
    let navigator: PreviewWebViewNavigatorType
    let usefulLinkURL: String
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let usefulLink = Driver
            .just("https://stackoverflow.com/questions/47754252/how-to-open-a-link-to-a-pdf-with-wkwebview")
            .map { URL(string: $0) }
            .unwrap()
        
        return Output(usefulLinkURL: usefulLink)
    }
}
