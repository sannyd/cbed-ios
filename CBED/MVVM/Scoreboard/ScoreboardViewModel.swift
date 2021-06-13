//
//  ScoreboardViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension ScoreboardViewModel {
    struct Input {
        
    }
    
    struct Output {
        
    }
}

struct ScoreboardViewModel: ViewModel {
    let useCase: ScoreboardUseCaseType
    let navigator: ScoreboardNavigatorType
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        return Output()
    }
}
