//
//  UserUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/07/2021.
//

import RxSwift

protocol ProfileUseCase {
    func getProfileInfo() -> Single<ProfileInfoM>
}

extension ProfileUseCase {
    func getProfileInfo() -> Single<ProfileInfoM> {
        return APIClient
            .shared
            .request(ProfileRouter.getProfileInfo)
    }
}
