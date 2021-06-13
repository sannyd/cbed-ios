//
//  SectionUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation
import RxSwift

protocol SectionsUseCase {
    func getSectionByID(id: String) -> Single<SectionM>
}

extension SectionsUseCase {
    func getSectionByID(id: String) -> Single<SectionM> {
        return APIClient
            .shared
            .request(SectionRouter.getSectionByID(id))
            .debug()
    }
}

