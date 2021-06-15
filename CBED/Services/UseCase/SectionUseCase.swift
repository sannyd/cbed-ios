//
//  SectionUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation
import RxSwift

protocol SectionAPIUseCase {
    func getSectionByID(id: String) -> Single<SectionDetailM>
}

extension SectionAPIUseCase {
    func getSectionByID(id: String) -> Single<SectionDetailM> {
        return APIClient
            .shared
            .request(SectionRouter.getSectionByID(id))
    }
}

