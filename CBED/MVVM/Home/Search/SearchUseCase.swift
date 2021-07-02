//
//  SearchUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 7/2/21.
//

import RxSwift

protocol SearchUseCaseType {
    func searchSection(request: SearchSectionRequestM) -> Single<SectionSearchResponseM>
}

struct SearchUseCase: SearchUseCaseType,
                      SectionAPIUseCase {
    
}
