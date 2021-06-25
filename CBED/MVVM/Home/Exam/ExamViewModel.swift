//
//  ExamViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 17/06/2021.
//

import RxSwift
import RxCocoa
import SwiftEntryKit

// MARK: Input + Output
extension ExamViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let answerTapped: Observable<IndexPath>
    }
    
    struct Output {
        let currentQuestion: Observable<QuestionM>
        let answers: Observable<[CommonCollectionViewSection<SelectableAnswer>]>
        let navigationTitle: Observable<String?>
        let numberOfQuestions: Observable<String>
    }
}

struct ExamViewModel: ViewModel {
    let useCase: ExamUseCaseType
    let navigator: ExamNavigatorType
    let sectionDetail: SectionDetailM
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let questions = sectionDetail.questions ?? []
        let currentQuestionIndex = BehaviorRelay<Int>(value: 0)
        let sharedCurrentQuestionIndex = currentQuestionIndex.share(replay: 1)
        let currentAnswers = BehaviorRelay<[CommonCollectionViewSection<SelectableAnswer>]>(value: [])
        let saveResultTrigger = PublishRelay<Void>()
        var correctAnswers = UserDefaults.standard.value(forKey: "\(sectionDetail.id)") as? Int ?? 0
        
        let sharedAlertPublisher = navigator
            .publisher
            .share(replay: 1)
        
        sharedAlertPublisher
            .map { delegate -> Void? in
                if case .cancelTapped = delegate {
                    return ()
                }
                return nil
            }
            .unwrap()
            .subscribe(onNext: { question in
                SwiftEntryKit.dismiss()
                let answers = (questions[currentQuestionIndex.value].answers ?? [])
                    .map { SelectableAnswer(isSelected: false, answer: $0) }
                currentAnswers.accept([CommonCollectionViewSection(items: answers)])
            })
            .disposed(by: disposeBag)
        
        let nextQuestion = sharedAlertPublisher
            .map { delegate -> QuestionAlertType? in
                if case .OKTapped(let questionAlertType) = delegate {
                    return questionAlertType
                }
                return nil
            }
            .unwrap()
            .do(onNext: { questionAlertType in
                switch questionAlertType {
                case .correct:
                    correctAnswers += 1
                    if currentQuestionIndex.value == (questions[currentQuestionIndex.value].answers ?? []).count {
                        saveResultTrigger.accept(())
                    } else {
                        currentQuestionIndex.accept(currentQuestionIndex.value + 1)
                        let answers = (questions[currentQuestionIndex.value].answers ?? [])
                            .map { SelectableAnswer(isSelected: false, answer: $0) }
                        currentAnswers.accept([CommonCollectionViewSection(items: answers)])
                    }
                case .wrong:
                    break
                }
                SwiftEntryKit.dismiss()
            })
            .map { _ in questions[currentQuestionIndex.value] }
        
       
        
        let initialQuestion = input
            .firstLoadTrigger
            .filter { currentQuestionIndex.value < questions.count - 1 }
            .map { questions[currentQuestionIndex.value] }
        
        let currentQuestion = Observable
            .merge(initialQuestion,
                   nextQuestion)
            .do(onNext: { question in
                let answers = (question.answers ?? [])
                    .map { SelectableAnswer(isSelected: false, answer: $0) }
                currentAnswers.accept([CommonCollectionViewSection(items: answers)])
            })
            .share(replay: 1)
        
        saveResultTrigger
            .withLatestFrom(currentQuestion)
            .map { ($0.answers?.count ?? 0, correctAnswers) }
            .flatMapLatest(saveResult(correct:totalQuestion:))
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToResultVC(result:))
            .disposed(by: disposeBag)
        
        let numberOfQuestions = sharedCurrentQuestionIndex
            .map { "Questions \($0)/\(questions.count)" }
        
        input
            .answerTapped
            .withLatestFrom(Observable.combineLatest(input.answerTapped,
                                                     currentAnswers))
            .map { indexPath, answerSections -> (AnswerM, CommonCollectionViewSection<SelectableAnswer>)? in
                if var answers = answerSections.first?.items {
                    var choosenAnswer = answers[indexPath.item]
                    choosenAnswer.isSelected = true
                    answers[indexPath.item] = choosenAnswer
                    
                    return (choosenAnswer.answer, CommonCollectionViewSection<SelectableAnswer>(items: answers))
                }
                return nil
            }
            .unwrap()
            .do(onNext: { _, answerSection in
                currentAnswers.accept([answerSection])
            })
            .map { $0.0 }
            .asDriverOnErrorJustComplete()
            .delay(.milliseconds(150))
            .drive(onNext: navigator.presentAnswerResult(answer:))
            .disposed(by: disposeBag)
        
        return Output(currentQuestion: currentQuestion,
                      answers: currentAnswers.asObservable(),
                      navigationTitle: .just(sectionDetail.name),
                      numberOfQuestions: numberOfQuestions)
    }
    
    private func saveResult(correct: Int,
                            totalQuestion: Int) -> Observable<SaveResultResponseM> {
        return self.useCase
            .saveSectionResult(id: sectionDetail.id, correct: correct, total: totalQuestion)
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
