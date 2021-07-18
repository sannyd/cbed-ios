//
//  SectionUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import RxSwift

protocol SectionsUseCaseType {
    func searchSection(request: SearchSectionRequestM) -> Single<SectionSearchResponseM>
    func getSectionByID(id: Int) -> Single<SectionDetailM>
}

struct SectionsUseCase: SectionsUseCaseType,
                        SectionAPIUseCase {
    
}
