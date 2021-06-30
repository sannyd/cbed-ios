//
//  SectionUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import RxSwift

protocol SectionsUseCaseType {
    func searchSection(keySearch: String,
                       limit: Int,
                       offset: Int) -> Single<SectionSearchResponseM>
}

struct SectionsUseCase: SectionsUseCaseType,
                        SectionAPIUseCase {
    
}
