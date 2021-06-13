//
//  LevelUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation
import RxSwift

protocol LevelsUseCase {
    func getAllLevels() -> Single<[LevelM]>
    func getLevelByID(_ id: String) -> Single<LevelM>
}

extension LevelsUseCase {
    func getAllLevels() -> Single<[LevelM]> {
        return APIClient
            .shared
            .request(LevelRouter.getAllLevels)
            .debug()
    }
    
    func getLevelByID(_ id: String) -> Single<LevelM> {
        return APIClient
            .shared
            .request(LevelRouter.getLevelByID(id))
            .debug()
    }
}
