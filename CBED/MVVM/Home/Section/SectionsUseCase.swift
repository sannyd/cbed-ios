//
//  SectionUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import RxSwift

protocol SectionsUseCaseType {
    func getLevelByID(_ id: Int) -> Single<LevelDetailM>
}

struct SectionsUseCase: SectionsUseCaseType,
                        LevelsUseCase {
    
}
