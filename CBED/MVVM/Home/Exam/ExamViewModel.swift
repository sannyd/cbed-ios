//
//  ExamViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 17/06/2021.
//

import RxSwift
import RxCocoa
import SwiftEntryKit
import WidgetKit

// MARK: Input + Output
extension ExamViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let answerTapped: Observable<IndexPath>
        let checkAnswerTapped: Observable<Void>
        let buttonEliminateAnswerTapped: Observable<Void>
    }
    
    struct Output {
        let currentQuestion: Observable<QuestionM>
        let answers: Observable<[CommonCollectionViewSection<SelectableAnswer>]>
        let navigationTitle: Observable<String?>
        let numberOfQuestions: Observable<String>
        let scrollToTopInvoked: Observable<Void>
        let timerText: Observable<String>
        let isDisableCheckAnswer: Observable<Bool>
        let eliminateButtonTitle: Observable<String>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct ExamViewModel: ViewModel {
    let useCase: ExamUseCaseType
    let navigator: ExamNavigatorType
    let sectionDetail: SectionDetailM
    let level: LevelM
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let isTwoChoiceQuestion = level.id == 30
        let pointsPerQuestion = isTwoChoiceQuestion ? 2 : 1
        let sectionKey = "section_\(sectionDetail.id)"
        let sectionStartTime = "section_start_time_\(sectionDetail.id)"
        let sectionEndTime = "section_end_time_\(sectionDetail.id)"
        let sectionResult = "section_result_\(sectionDetail.id)"
        let sectionFirstAttemptScoresKey = "section_first_attempt_scores_\(sectionDetail.id)"
        
        func removeAllSavedSectionData() {
            UserDefaults.standard.removeObject(forKey: sectionKey)
            UserDefaults.standard.removeObject(forKey: sectionStartTime)
            UserDefaults.standard.removeObject(forKey: sectionEndTime)
            UserDefaults.standard.removeObject(forKey: sectionResult)
            UserDefaults.standard.removeObject(forKey: sectionFirstAttemptScoresKey)
        }
        
        let questions = sectionDetail.questions ?? []
        let maximumScore = questions.count * pointsPerQuestion
        var previousQuestionIndex = UserDefaults.standard.value(forKey: sectionKey) as? Int ?? 0
        let currentQuestionIndex = BehaviorRelay<Int>(value: previousQuestionIndex)
        let currentSelectedAnswers = BehaviorRelay<[IndexPath]>(value: [])
        let currentFocusedAnswer = BehaviorRelay<IndexPath?>(value: nil)
        let sharedCurrentQuestionIndex = currentQuestionIndex.share(replay: 1)
        let currentAnswers = BehaviorRelay<[CommonCollectionViewSection<SelectableAnswer>]>(value: [])
        let saveResultTrigger = PublishRelay<Void>()
        let previousCorrectAnswers = UserDefaults.standard.value(forKey: sectionResult) as? Int ?? 0
        var correctAnswers = min(previousCorrectAnswers, maximumScore)
        var firstAttemptScores = UserDefaults.standard.array(forKey: sectionFirstAttemptScoresKey) as? [Int] ?? Array(repeating: -1, count: questions.count)
        if firstAttemptScores.count != questions.count {
            firstAttemptScores = Array(repeating: -1, count: questions.count)
        }
        let scrollToTopInvoked = PublishSubject<Void>()
        let timerTrigger = PublishSubject<String>()
        let resetSectionTrigger = PublishSubject<Void>()
        let isEliminateAnswerSelected = BehaviorRelay<Bool>(value: false)
        let eliminateButtonTitle = BehaviorRelay<String>(value: "Eliminate answer")
        
        func makeSelectableAnswers(for question: QuestionM, shouldShuffle: Bool = true) -> [SelectableAnswer] {
            let answers = (question.answers ?? [])
                .map { SelectableAnswer(isSelected: false,
                                        isCheck: false,
                                        isEliminated: false,
                                        answer: $0) }
            return shouldShuffle ? answers.shuffled() : answers
        }
        
        func selectedIndexPaths(from answers: [SelectableAnswer]) -> [IndexPath] {
            answers.enumerated().compactMap { index, answer in
                answer.isSelected ? IndexPath(item: index, section: 0) : nil
            }
        }
        
        func resetSelectionState() {
            currentSelectedAnswers.accept([])
            currentFocusedAnswer.accept(nil)
            eliminateButtonTitle.accept("Eliminate answer")
        }
        
        func advanceToNextQuestionOrSaveResult() {
            if currentQuestionIndex.value >= questions.count - 1 {
                saveResultTrigger.accept(())
            } else {
                let nextQuestionIndex = currentQuestionIndex.value + 1
                currentQuestionIndex.accept(nextQuestionIndex)
                let answers = makeSelectableAnswers(for: questions[currentQuestionIndex.value])
                currentAnswers.accept([CommonCollectionViewSection(items: answers)])
                
                UserDefaults.standard.setValue(nextQuestionIndex, forKey: sectionKey)
                UserDefaults.standard.setValue(correctAnswers, forKey: sectionResult)
                UserDefaults.standard.set(firstAttemptScores, forKey: sectionFirstAttemptScoresKey)
                scrollToTopInvoked.onNext(())
            }
        }
        
        func explanationText(for answers: [SelectableAnswer], selectedAnswers: [SelectableAnswer], isTwoChoiceQuestion: Bool) -> String? {
            let prioritizedAnswers = isTwoChoiceQuestion ? answers.filter { $0.answer.isCorrect } : selectedAnswers
            let discussions = prioritizedAnswers
                .compactMap { $0.answer.discussion?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
            
            let uniqueDiscussions = discussions.reduce(into: [String]()) { partialResult, discussion in
                if !partialResult.contains(discussion) {
                    partialResult.append(discussion)
                }
            }
            
            if !uniqueDiscussions.isEmpty {
                return uniqueDiscussions.joined(separator: "\n\n")
            }
            
            return selectedAnswers
                .compactMap { $0.answer.discussion?.trimmingCharacters(in: .whitespacesAndNewlines) }
                .first(where: { !$0.isEmpty })
        }
        
        func evaluationResult(for answers: [SelectableAnswer]) -> QuestionEvaluationResult? {
            let selectedAnswers = answers.filter(\.isSelected)
            guard !selectedAnswers.isEmpty else {
                return nil
            }
            
            let awardedPoints: Int
            let type: QuestionAlertType
            
            if isTwoChoiceQuestion {
                let correctSelections = selectedAnswers.filter { $0.answer.isCorrect }.count
                awardedPoints = min(correctSelections, 2)
                
                switch awardedPoints {
                case 2:
                    type = .correct(points: awardedPoints)
                    AudioFeedbackManager.shared.playIfEnabled(.correct)
                case 1:
                    type = .partial(points: awardedPoints)
                    AudioFeedbackManager.shared.playIfEnabled(.correct)
                default:
                    type = .wrong(points: 0)
                    AudioFeedbackManager.shared.playIfEnabled(.incorrect)
                }
            } else {
                let isCorrect = selectedAnswers.first?.answer.isCorrect ?? false
                awardedPoints = isCorrect ? 1 : 0
                type = isCorrect ? .correct(points: awardedPoints) : .wrong(points: 0)
                AudioFeedbackManager.shared.playIfEnabled(isCorrect ? .correct : .incorrect)
            }
            
            return QuestionEvaluationResult(type: type,
                                            description: explanationText(for: answers,
                                                                         selectedAnswers: selectedAnswers,
                                                                         isTwoChoiceQuestion: isTwoChoiceQuestion))
        }
        
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
                    let potentialMultiplier = ceil(Double(Double(questionCount) / 100))
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
        
        input
            .answerTapped
            .subscribe(onNext: { index in
                let answer = currentAnswers.value.first?.items ?? []
                guard answer.indices.contains(index.item) else {
                    return
                }
                
                let item = answer[index.item]
                eliminateButtonTitle.accept(item.isEliminated ? "Uneliminate answer" : "Eliminate answer")
                currentFocusedAnswer.accept(index)
            })
            .disposed(by: disposeBag)
        
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
                let answers = makeSelectableAnswers(for: questions[currentQuestionIndex.value])
                    .map {
                        var answer = $0
                        answer.isCheck = true
                        return answer
                    }
                currentAnswers.accept([CommonCollectionViewSection(items: answers)])
                resetSelectionState()
            })
            .disposed(by: disposeBag)
        
        var previousIncorrectAnswerIndex: Int?
        
        let nextQuestion = sharedAlertPublisher
            .map { delegate -> QuestionAlertType? in
                if case .OKTapped(let questionAlertType) = delegate {
                    return questionAlertType
                }
                return nil
            }
            .unwrap()
            .do(onNext: { questionAlertType in
                isEliminateAnswerSelected.accept(false)
                
                switch questionAlertType {
                case .correct(let points),
                     .partial(let points):
                    if isTwoChoiceQuestion {
                        if firstAttemptScores.indices.contains(currentQuestionIndex.value),
                           firstAttemptScores[currentQuestionIndex.value] == -1 {
                            firstAttemptScores[currentQuestionIndex.value] = points
                            correctAnswers += points
                            UserDefaults.standard.setValue(correctAnswers, forKey: sectionResult)
                            UserDefaults.standard.set(firstAttemptScores, forKey: sectionFirstAttemptScoresKey)
                        }
                        
                        if case .correct(_) = questionAlertType {
                            advanceToNextQuestionOrSaveResult()
                        }
                    } else if isLevelNeedToHaveMoreThan90(level.id) {
                        if previousIncorrectAnswerIndex != currentQuestionIndex.value {
                            correctAnswers += points
                        }
                    } else {
                        correctAnswers += points
                    }
                    
                    if !isTwoChoiceQuestion {
                        advanceToNextQuestionOrSaveResult()
                    }
                case .wrong:
                    if isTwoChoiceQuestion {
                        if firstAttemptScores.indices.contains(currentQuestionIndex.value),
                           firstAttemptScores[currentQuestionIndex.value] == -1 {
                            firstAttemptScores[currentQuestionIndex.value] = 0
                            UserDefaults.standard.set(firstAttemptScores, forKey: sectionFirstAttemptScoresKey)
                        }
                    } else if isLevelNeedToHaveMoreThan90(level.id) {
                        previousIncorrectAnswerIndex = currentQuestionIndex.value
                    } else {
                        advanceToNextQuestionOrSaveResult()
                    }
                }
                
                resetSelectionState()
                SwiftEntryKit.dismiss()
            })
            .map { _ in questions[currentQuestionIndex.value] }
        
        sharedAlertPublisher
            .map { delegate -> String? in
                if case .openUseLink(let link) = delegate {
                    return link
                }
                return nil
            }
            .unwrap()
            .asDriverOnErrorJustComplete()
//            .do(onNext: { _ in
//                SwiftEntryKit.dismiss()
//            })
            .drive(onNext: navigator.pushToPreviewWebView(usefulLinkURL:))
            .disposed(by: disposeBag)
       
        
        let initialQuestion = Observable.merge(resetSectionTrigger,
                                               input.firstLoadTrigger)
            .filter { currentQuestionIndex.value <= questions.count - 1 }
            .map { questions[currentQuestionIndex.value] }
        
        let currentQuestion = Observable
            .merge(initialQuestion,
                   nextQuestion)
            .do(onNext: { question in
                let answers = makeSelectableAnswers(for: question)
                currentAnswers.accept([CommonCollectionViewSection(items: answers)])
                resetSelectionState()
            })
            .share(replay: 1)
        
        saveResultTrigger
            .map { (correctAnswers, maximumScore) }
            .flatMapLatest(saveResult(correct:totalQuestion:))
            .flatMapLatest { saveResultResponse in
                self.getProfile()
                    .do { profile in
                        Storage.profileInfo = profile
                        Storage.currentLevel = profile.lastSectionName
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                    .map { _ in saveResultResponse }
            }
            .asDriverOnErrorJustComplete()
            .do(onNext: { _ in
                removeAllSavedSectionData()
            })
            .drive(onNext: navigator.pushToResultVC(result:))
            .disposed(by: disposeBag)
        
        let numberOfQuestions = sharedCurrentQuestionIndex
            .map { "Question \($0 + 1)/\(questions.count)" }
        
        input
            .answerTapped
            .withLatestFrom(currentAnswers) { ($0, $1) }
            .map { indexPath, answerSections -> [SelectableAnswer]? in
                guard var answers = answerSections.first?.items,
                      answers.indices.contains(indexPath.item) else {
                    return nil
                }
                
                if isTwoChoiceQuestion {
                    var choosenAnswer = answers[indexPath.item]
                    let selectedCount = answers.filter(\.isSelected).count
                    
                    if choosenAnswer.isSelected {
                        choosenAnswer.isSelected = false
                    } else {
                        guard selectedCount < 2 else {
                            return answers
                        }
                        choosenAnswer.isSelected = true
                    }
                    
                    answers[indexPath.item] = choosenAnswer
                } else {
                    answers = answers.map {
                        var answer = $0
                        answer.isSelected = false
                        return answer
                    }
                    
                    var choosenAnswer = answers[indexPath.item]
                    choosenAnswer.isSelected = true
                    answers[indexPath.item] = choosenAnswer
                }
                
                return answers
            }
            .unwrap()
            .subscribe(onNext: { answers in
                AudioFeedbackManager.shared.playButtonTapIfEnabled()
                currentSelectedAnswers.accept(selectedIndexPaths(from: answers))
                let focusedIndexPath = currentFocusedAnswer.value
                let nextFocusedAnswer: IndexPath?
                
                if let focusedIndexPath,
                   answers.indices.contains(focusedIndexPath.item),
                   answers[focusedIndexPath.item].isSelected {
                    nextFocusedAnswer = focusedIndexPath
                } else {
                    nextFocusedAnswer = selectedIndexPaths(from: answers).last
                }
                
                currentFocusedAnswer.accept(nextFocusedAnswer)
                currentAnswers.accept([CommonCollectionViewSection(items: answers)])
            })
            .disposed(by: disposeBag)
        
        input
            .checkAnswerTapped
            .withLatestFrom(currentAnswers)
            .compactMap { $0.first?.items }
            .compactMap(evaluationResult(for:))
            .map { ($0, level, questions[currentQuestionIndex.value].youtubeURL) }
            .asDriverOnErrorJustComplete()
            .delay(.milliseconds(100))
            .drive(onNext: navigator.presentAnswerResult(result:level:explainationLink:))
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
                    firstAttemptScores = Array(repeating: -1, count: questions.count)
                    resetSelectionState()
                }
            })
            .disposed(by: disposeBag)
        
        let isDisableCheckAnswer = currentSelectedAnswers
            .map { !$0.isEmpty }
        
        
        input.buttonEliminateAnswerTapped
            .withLatestFrom(currentFocusedAnswer)
            .unwrap()
            .subscribe(onNext: { selectIndex in
                let answers = currentAnswers.value.first?.items ?? []
                var temp: [SelectableAnswer] = []
                for (index, answer) in answers.enumerated() {
                    if selectIndex.item == index {
                        var tempAnswer = answer
                        tempAnswer.isEliminated = !tempAnswer.isEliminated
                        
                        if tempAnswer.isEliminated {
                            eliminateButtonTitle.accept("Uneliminate answer")
                        } else {
                            eliminateButtonTitle.accept("Eliminate answer")
                        }
                        
                        temp.append(tempAnswer)
                    } else {
                        temp.append(answer)
                    }
                }
                
                currentAnswers.accept([CommonCollectionViewSection(items: temp)])
            })
            .disposed(by: disposeBag)
        
        return Output(currentQuestion: currentQuestion,
                      answers: currentAnswers.asObservable(),
                      navigationTitle: .just(sectionDetail.name),
                      numberOfQuestions: numberOfQuestions,
                      scrollToTopInvoked: scrollToTopInvoked.asObservable(),
                      timerText: timerTrigger.asObservable(),
                      isDisableCheckAnswer: isDisableCheckAnswer,
                      eliminateButtonTitle: eliminateButtonTitle.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
    }
    
    private func isLevelNeedToHaveMoreThan90(_ level: Int) -> Bool {
        let ids = [
            8, // Free Essay Drill Sample
            5, // MBE Level Drills
            29, // NG MCQ 1-Choice
            15, // CA MCQ Drills
            4, // FL MCQ Drills
            9, // CA Essay Drills & Videos
            7, // MEE Drills & Videos
            31, // IQS Drafting Sets
            13, // FL Essay Drills
            14, // GA Essay Drills
            10, // CPT Essay Drills
            11, // MPT Essay Drills
            17, // MPRE Drills
            21, // Agency
            22, // Partnerships
            23, // Corps
            24, // Conflicts
            25, // Fam-Law
            26, // Trusts
            27, // Wills
            28 // Sec-Trans
        ]
        
        if ids.contains(level) {
            return true
        }
        return false
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
    
    private func getProfile() -> Observable<ProfileInfoM> {
        return useCase
            .getProfileInfo()
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
}
