//
//  AppViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 23/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension AppViewModel {
    struct Input {
//        let firstLoadTrigger: Observable<Void>
    }
    
    struct Output {
        
    }
}

struct AppViewModel: ViewModel {
    let useCase: AppUseCaseType
    let navigator: AppNavigatorType
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
     return Output()
        
    }
}
