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
    func searchSection(request: SearchSectionRequestM) -> Single<SectionSearchResponseM>
    func searchEssay(request: SearchSectionRequestM) -> Single<SectionSearchResponseM>
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
    
    func searchSection(request: SearchSectionRequestM) -> Single<SectionSearchResponseM> {
        guard let params = request.toParams() else {
            return .error(CustomError.CannotGetParams)
        }
        return APIClient
            .shared
            .request(SectionRouter.searchSection(params: params))
    }
    
    func searchEssay(request: SearchSectionRequestM) -> Single<SectionSearchResponseM> {
        guard let params = request.toParams() else {
            return .error(CustomError.CannotGetParams)
        }
        return APIClient
            .shared
            .request(SectionRouter.searchEssays(params: params))
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

