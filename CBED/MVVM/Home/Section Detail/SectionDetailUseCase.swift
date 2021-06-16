//
//  SectionDetailUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import RxSwift

protocol SectionDetailUseCaseType {
    func getSectionByID(id: Int) -> Single<SectionDetailM>
}

struct SectionDetailUseCase: SectionDetailUseCaseType,
                             SectionAPIUseCase {
    
}
