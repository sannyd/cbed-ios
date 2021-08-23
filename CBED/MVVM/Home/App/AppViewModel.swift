//
//  AppViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 23/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension AppViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
    }
    
    struct Output {
        let loadAppTrigger: Observable<Bool>
        let isLoading: Observable<Bool>
        let error: Observable<Error>
    }
}

struct AppViewModel: ViewModel {
    let useCase: AppUseCaseType
    let navigator: AppNavigatorType
    
    let errorTracker = ErrorTracker()
    let activityIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let loadAppTrigger = PublishSubject<Bool>()
        
        input
            .firstLoadTrigger
            .flatMapLatest(fetchProfileInfo)
            .subscribe { profile in
                Storage.profileInfo = profile
                loadAppTrigger.onNext(true)
            } onError: { error in
                loadAppTrigger.onNext(false)
            }
            .disposed(by: disposeBag)
        
        return Output(loadAppTrigger: loadAppTrigger.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
        
    }
    
    private func fetchProfileInfo() -> Observable<ProfileInfoM> {
        return self.useCase
            .getProfileInfo()
            .trackActivity(self.activityIndicator)
            .trackError(self.errorTracker)
            .catch({ (error) -> Observable<ProfileInfoM> in
                return .error(error)
            })
    }
}
