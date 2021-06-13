//
//  SettingViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension SettingViewModel {
    struct Input {
        
    }
    
    struct Output {
        
    }
}

struct SettingViewModel: ViewModel {
    let useCase: SettingUseCaseType
    let navigator: SettingNavigatorType
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        return Output()
    }
}
