//
//  SectionUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation
import RxSwift

protocol SectionAPIUseCase {
    func getSectionByID(id: Int) -> Single<SectionDetailM>
    func searchSection(keySearch: String,
                       limit: Int,
                       offset: Int) -> Single<SectionSearchResponseM>
    func saveSectionResult(id: Int,
                           correct: Int,
                           total: Int) -> Single<SaveResultResponseM>
}

extension SectionAPIUseCase {
    func getSectionByID(id: Int) -> Single<SectionDetailM> {
        return APIClient
            .shared
            .request(SectionRouter.getSectionByID(id))
    }
    
    func searchSection(keySearch: String,
                       limit: Int,
                       offset: Int) -> Single<SectionSearchResponseM> {
        return APIClient
            .shared
            .request(SectionRouter.searchSection(keySearch: keySearch,
                                                 limit: limit,
                                                 offset: offset))
    }
    
    func saveSectionResult(id: Int,
                           correct: Int,
                           total: Int) -> Single<SaveResultResponseM> {
        return APIClient
            .shared
            .request(SectionRouter.saveSectionResult(id: id,
                                                     correct: correct,
                                                     total: total))
    }
}

