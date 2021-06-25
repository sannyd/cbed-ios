//
//  ExamUseCase.swift
//  CBED
//
//  Created by Jimmy Hoang on 17/06/2021.
//

import RxSwift

protocol ExamUseCaseType {
    func saveSectionResult(id: Int,
                           correct: Int,
                           total: Int) -> Single<SaveResultResponseM>
}

struct ExamUseCase: ExamUseCaseType,
                    SectionAPIUseCase {
    
}
