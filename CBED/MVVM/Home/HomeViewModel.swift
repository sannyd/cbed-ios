//
//  HomeViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension HomeViewModel {
    struct Input {
        
    }
    
    struct Output {
        
    }
}

struct HomeViewModel: ViewModel {
    let useCase: HomeUseCaseType
    let navigator: HomeNavigatorType
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        
    }
}
