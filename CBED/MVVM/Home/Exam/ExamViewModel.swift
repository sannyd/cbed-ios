//
//  ExamViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 17/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension ExamViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let answerTapped: Observable<AnswerM>
        let correctAlertTapped: Observable<Void>
        let wrongAlertTapped: Observable<Void>
    }
    
    struct Output {
        let currentQuestion: Observable<QuestionM>
    }
}

struct ExamViewModel: ViewModel {
    let useCase: ExamUseCaseType
    let navigator: ExamNavigatorType
    let sectionDetail: SectionDetailM
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let questions = sectionDetail.questions ?? []
        var index = 0
        
        let nextQuestion = input
            .correctAlertTapped
            .do(onNext: { _ in
                index += 1
            })
            .map { questions[index] }
        
        let initialQuestion = input
            .firstLoadTrigger
            .map { questions[index] }
        
        let currentQuestion = Observable
            .merge(initialQuestion,
                   nextQuestion)
        
        return Output(currentQuestion: currentQuestion)
    }
}
