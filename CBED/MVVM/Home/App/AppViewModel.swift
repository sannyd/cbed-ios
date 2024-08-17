//
//  AppViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 23/06/2021.
//

import RxSwift
import RxCocoa
import WidgetKit

// MARK: Input + Output
extension AppViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
    }
    
    struct Output {
        let loadAppTrigger: Observable<(Bool, [String: Any]?)>
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
        let loadAppTrigger = PublishSubject<(Bool, [String: Any]?)>()
        
        input
            .firstLoadTrigger
            .flatMapLatest(fetchProfileInfo)
            .do(onNext: { profile in
                Storage.profileInfo = profile
                Storage.currentLevel = profile.lastSectionName
                WidgetCenter.shared.reloadAllTimelines()
            }, onError: { error in
                loadAppTrigger.onNext((false, nil))
            })
            .mapToVoid()
            .flatMapLatest(fetchConfigs)
            .subscribe { configs in
                loadAppTrigger.onNext((true, configs))
            } onError: { error in
                loadAppTrigger.onNext((false, nil))
            }
            .disposed(by: disposeBag)
        
        
        
        return Output(loadAppTrigger: loadAppTrigger.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
        
    }
    
    
    private func fetchConfigs() -> Observable<[String: Any]> {
        print("[Remote Config] Start fetching")
        return APIClient
            .shared
            .requestAsDict(AuthRouter.config)
            .trackActivity(self.activityIndicator)
            .trackError(self.errorTracker)
            .catch({ (error) -> Observable<[String: Any]> in
                return .error(error)
            })
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
