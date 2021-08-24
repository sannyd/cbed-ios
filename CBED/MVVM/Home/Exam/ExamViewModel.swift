//
//  ExamViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 17/06/2021.
//

import RxSwift
import RxCocoa
import SwiftEntryKit
import SwiftySound

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
        let timerText: Observable<String>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
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
        let sectionStartTime = "section_start_time_\(sectionDetail.id)"
        let sectionEndTime = "section_end_time_\(sectionDetail.id)"
        let sectionResult = "section_result_\(sectionDetail.id)"
        
        func removeAllSavedSectionData() {
            UserDefaults.standard.removeObject(forKey: sectionKey)
            UserDefaults.standard.removeObject(forKey: sectionStartTime)
            UserDefaults.standard.removeObject(forKey: sectionEndTime)
            UserDefaults.standard.removeObject(forKey: sectionResult)
        }
        
        let questions = sectionDetail.questions ?? []
        var previousQuestionIndex = UserDefaults.standard.value(forKey: sectionKey) as? Int ?? 0
        let currentQuestionIndex = BehaviorRelay<Int>(value: previousQuestionIndex)
        let sharedCurrentQuestionIndex = currentQuestionIndex.share(replay: 1)
        let currentAnswers = BehaviorRelay<[CommonCollectionViewSection<SelectableAnswer>]>(value: [])
        let saveResultTrigger = PublishRelay<Void>()
        let previousCorrectAnswers = UserDefaults.standard.value(forKey: sectionResult) as? Int ?? 0
        var correctAnswers = previousCorrectAnswers <= questions.count ? previousCorrectAnswers : questions.count - 1
        let scrollToTopInvoked = PublishSubject<Void>()
        let timerTrigger = PublishSubject<String>()
        let resetSectionTrigger = PublishSubject<Void>()
        
        UserDefaults.standard.setValue(Date(), forKey: sectionStartTime)
        
        Observable<Int>.timer(.seconds(0),
                               period: .seconds(1),
                               scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                if let startTime = UserDefaults.standard.value(forKey: sectionStartTime) as? Date,
                   let endTime = UserDefaults.standard.value(forKey: sectionEndTime) as? Date {
                    guard endTime > startTime else {
                        removeAllSavedSectionData()
                        navigator.popViewController()
                        return
                    }
                    let components = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: startTime, to: endTime)
                    let dayString = components.day == nil || components.day == 0 ? "" : "\(components.day!)D"
                    let hourString = components.hour == nil || components.hour == 0  ? "" : "\(components.hour!)hr"
                    let minuteString = components.minute == nil || components.minute == 0 ? "" : "\(components.minute!)m"
                    let secondString = components.second == nil ? "" : "\(components.second!)s"
                    UserDefaults.standard.setValue(Date(), forKey: sectionStartTime)
                    timerTrigger.onNext("\(dayString) \(hourString) \(minuteString) \(secondString)")
                } else {
                    let startTime = Date()
                    let questionCount = questions.count == 0 ? 100 : questions.count
                    let potentialMultiplier = ceil(Double(questionCount / 100))
                    let multiplier = potentialMultiplier == 0 ? 1 : potentialMultiplier
                    let calendar = Calendar.current
                    let endTime = calendar.date(byAdding: .hour, value: Int(multiplier) * 24, to: startTime)
                    UserDefaults.standard.setValue(startTime, forKey: sectionStartTime)
                    UserDefaults.standard.setValue(endTime, forKey: sectionEndTime)
                }
            })
            .disposed(by: disposeBag)
        
        
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
                    if currentQuestionIndex.value >= questions.count - 1 {
                        saveResultTrigger.accept(())
                    } else {
                        let nextQuestionIndex = currentQuestionIndex.value + 1
                        currentQuestionIndex.accept(nextQuestionIndex)
                        let answers = (questions[currentQuestionIndex.value].answers ?? [])
                            .map { SelectableAnswer(isSelected: false, answer: $0) }
                        currentAnswers.accept([CommonCollectionViewSection(items: answers)])
                        
                        UserDefaults.standard.setValue(nextQuestionIndex, forKey: sectionKey)
                        UserDefaults.standard.setValue(correctAnswers, forKey: sectionResult)
                    }
                case .wrong:
                    if currentQuestionIndex.value >= questions.count - 1 {
                        saveResultTrigger.accept(())
                    } else {
                        let nextQuestionIndex = currentQuestionIndex.value + 1
                        currentQuestionIndex.accept(nextQuestionIndex)
                        let answers = (questions[currentQuestionIndex.value].answers ?? [])
                            .map { SelectableAnswer(isSelected: false, answer: $0) }
                        currentAnswers.accept([CommonCollectionViewSection(items: answers)])
                        
                        UserDefaults.standard.setValue(nextQuestionIndex, forKey: sectionKey)
                    }
                }
                scrollToTopInvoked.onNext(())
                SwiftEntryKit.dismiss()
            })
            .map { _ in questions[currentQuestionIndex.value] }
        
       
        
        let initialQuestion = Observable.merge(resetSectionTrigger,
                                               input.firstLoadTrigger)
            .filter { currentQuestionIndex.value <= questions.count - 1 }
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
                removeAllSavedSectionData()
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
                    if choosenAnswer.answer.isCorrect {
                        if let url = Bundle.main.url(forResource: "DING", withExtension: "mp3") {
                            Sound.play(url: url)
                        }
                    } else {
                        if let url = Bundle.main.url(forResource: "KICK", withExtension: "mp3") {
                            Sound.play(url: url)
                        }
                    }
                    
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
        
        navigator.resultViewPublisher
            .subscribe(onNext: { events in
                switch events {
                case .tryAgainTapped:
                    // Remove all saved data in user defaults
                    removeAllSavedSectionData()
                    
                    // Reset all values
                    previousQuestionIndex = 0
                    currentQuestionIndex.accept(previousQuestionIndex)
                    correctAnswers = 0
                }
            })
            .disposed(by: disposeBag)
        
        
        return Output(currentQuestion: currentQuestion,
                      answers: currentAnswers.asObservable(),
                      navigationTitle: .just(sectionDetail.name),
                      numberOfQuestions: numberOfQuestions,
                      scrollToTopInvoked: scrollToTopInvoked.asObservable(),
                      timerText: timerTrigger.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    private func saveResult(correct: Int,
                            totalQuestion: Int) -> Observable<SaveResultResponseM> {
        return self.useCase
            .saveSectionResult(id: sectionDetail.id, correct: correct <= totalQuestion ? correct : totalQuestion, total: totalQuestion)
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
