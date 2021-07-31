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
        let viewWillAppear: Observable<Void>
    }
    
    struct Output {
        let profileInfo: Observable<ProfileInfoM>
    }
}

struct SettingViewModel: ViewModel {
    let useCase: SettingUseCaseType
    let navigator: SettingNavigatorType
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let userProfile = input
            .viewWillAppear
            .map { _ in Storage.profileInfo }
        
        return Output(profileInfo: userProfile.unwrap())
    }
}
