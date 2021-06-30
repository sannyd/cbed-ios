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
//    func getLevelByID(_ id: Int) -> Single<LevelDetailM>
}

extension LevelsUseCase {
    func getAllLevels() -> Single<[LevelM]> {
        return APIClient
            .shared
            .request(LevelRouter.getAllLevels)
    }
    
//    func getLevelByID(_ id: Int) -> Single<LevelDetailM> {
//        return APIClient
//            .shared
//            .request(LevelRouter.getLevelByID(id))
//    }
}
