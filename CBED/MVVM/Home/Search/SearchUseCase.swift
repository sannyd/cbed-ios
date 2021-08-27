//
//  SearchUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 7/2/21.
//

import RxSwift

protocol SearchUseCaseType {
    func searchSection(request: SearchSectionRequestM) -> Single<SectionSearchResponseM>
    func searchEssay(request: SearchSectionRequestM) -> Single<SectionSearchResponseM>
    func getSectionByID(id: Int) -> Single<SectionDetailM>
}

struct SearchUseCase: SearchUseCaseType,
                      SectionAPIUseCase {
    
}
