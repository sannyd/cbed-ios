//
//  AppUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 23/06/2021.
//

import RxSwift

protocol AppUseCaseType {
    func getProfileInfo() -> Single<ProfileInfoM>
}

struct AppUseCase: AppUseCaseType,
                   ProfileUseCase {
    
}
