import RxSwift
import RxCocoa

// MARK: Input + Output
extension NestedLevelViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let viewWillAppear: Observable<Void>
        let levelTapped: Observable<LevelM>
    }
    
    struct Output {
        let levels: Driver<[CommonCollectionViewSection<LevelM>]>
        let title: Driver<String>
        let isLoading: Driver<Bool>
        let error: Driver<Error>
    }
}

struct NestedLevelViewModel: ViewModel {
    let useCase: LevelUseCaseType
    let navigator: NestedLevelNavigator
    let nestedLevels: [LevelM]
    let title: String
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    private let loadindIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let levels = input
            .firstLoadTrigger
            .map { nestedLevels }
            .map { [CommonCollectionViewSection(items: $0)] }
        
        input
            .levelTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToSectionsVC(level:))
            .disposed(by: disposeBag)

        return Output(
            levels: levels.asDriver(onErrorJustReturn: []),
            title: .just(title),
            isLoading: loadindIndicator.asDriver(),
            error: errorTracker.asDriver()
        )
    }
}
