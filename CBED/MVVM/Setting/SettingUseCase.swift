//
//  SettingUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import RxSwift

protocol SettingUseCaseType {
    func getProfileInfo() -> Single<ProfileInfoM>
}

struct SettingUseCase: SettingUseCaseType,
                       ProfileUseCase {
    
}
