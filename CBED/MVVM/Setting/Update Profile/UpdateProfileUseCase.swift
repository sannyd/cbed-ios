//
//  UpdateProfileUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 8/29/21.
//

import RxSwift

protocol UpdateProfileUseCaseType {
    func updateProfileInfo(request: UpdateProfileRequestM,
                           imageData: Data?) -> Single<ProfileInfoM>
}

struct UpdateProfileUseCase: UpdateProfileUseCaseType,
                             ProfileUseCase {
    
}
