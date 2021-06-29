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
        let scrollToTopInvoked: Observable<Void>
    }
}

struct ExamViewModel: ViewModel {
    let useCase: ExamUseCaseType
    let navigator: ExamNavigatorType
    let sectionDetail: SectionDetailM
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let sectionKey = "section_\(sectionDetail.id)"
        
        let questions = sectionDetail.questions ?? []
        let previousQuestionIndex = UserDefaults.standard.value(forKey: sectionKey) as? Int ?? 0
        let currentQuestionIndex = BehaviorRelay<Int>(value: previousQuestionIndex)
        let sharedCurrentQuestionIndex = currentQuestionIndex.share(replay: 1)
        let currentAnswers = BehaviorRelay<[CommonCollectionViewSection<SelectableAnswer>]>(value: [])
        let saveResultTrigger = PublishRelay<Void>()
        var correctAnswers = previousQuestionIndex + 1
        let scrollToTopInvoked = PublishSubject<Void>()
        
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
                    if currentQuestionIndex.value >= questions.count - 1 {
                        saveResultTrigger.accept(())
                    } else {
                        correctAnswers += 1
                        let nextQuestionIndex = currentQuestionIndex.value + 1
                        currentQuestionIndex.accept(currentQuestionIndex.value + 1)
                        let answers = (questions[currentQuestionIndex.value].answers ?? [])
                            .map { SelectableAnswer(isSelected: false, answer: $0) }
                        currentAnswers.accept([CommonCollectionViewSection(items: answers)])
                        
                        UserDefaults.standard.setValue(nextQuestionIndex, forKey: sectionKey)
                    }
                    scrollToTopInvoked.onNext(())
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
            .map { (correctAnswers, questions.count) }
            .flatMapLatest(saveResult(correct:totalQuestion:))
            .asDriverOnErrorJustComplete()
            .do(onNext: { _ in
                UserDefaults.standard.removeObject(forKey: sectionKey)
            })
            .drive(onNext: navigator.pushToResultVC(result:))
            .disposed(by: disposeBag)
        
        let numberOfQuestions = sharedCurrentQuestionIndex
            .map { "Questions \($0 + 1)/\(questions.count)" }
        
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
                      numberOfQuestions: numberOfQuestions,
                      scrollToTopInvoked: scrollToTopInvoked.asObservable())
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
