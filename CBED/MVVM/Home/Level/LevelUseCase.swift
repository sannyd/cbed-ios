//
//  LevelUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import RxSwift

protocol LevelUseCaseType {
    func getAllLevels() -> Single<[LevelM]>
//    func getLevelByID(_ id: Int) -> Single<LevelDetailM>
//    func searchSection(request: SearchSectionRequestM) -> Single<SectionSearchResponseM>
}

struct LevelUseCase: LevelUseCaseType,
                     LevelsUseCase,
                     SectionAPIUseCase {
    
}
