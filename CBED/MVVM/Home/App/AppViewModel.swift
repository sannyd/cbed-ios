//
//  AppViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 23/06/2021.
//

import RxSwift
import RxCocoa
import WidgetKit
import Firebase

// MARK: Input + Output
extension AppViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
    }
    
    struct Output {
        let loadAppTrigger: Observable<(Bool, [[String: Any]]?)>
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
        let loadAppTrigger = PublishSubject<(Bool, [[String: Any]]?)>()
        var isProfileLoaded = false
        input
            .firstLoadTrigger
            .flatMapLatest(fetchProfileInfo)
            .do(onNext: { profile in
                if !profile.email.isEmpty {
                    Storage.profileInfo = profile
                    Storage.currentLevel = profile.lastSectionName
                    WidgetCenter.shared.reloadAllTimelines()
                    // Lock Firebase Analytics session to this logged-in user
                    // so per-user app usage is attributable in GA4.
                    if let uid = profile.id {
                        Analytics.setUserID(String(uid))
                    }
                    isProfileLoaded = true
                }
            })
            .mapToVoid()
            .flatMapLatest(fetchConfigs)
            .subscribe { configs in
                loadAppTrigger.onNext((isProfileLoaded, configs))
            } onError: { error in
                loadAppTrigger.onNext((isProfileLoaded, nil))
            }
            .disposed(by: disposeBag)
        
        return Output(loadAppTrigger: loadAppTrigger.asObservable(),
                      isLoading: activityIndicator.asObservable(),
                      error: errorTracker.asObservable())
        
    }
    
    
    private func fetchConfigs() -> Observable<[[String: Any]]> {
        print("[Remote Config] Start fetching")
        return APIClient
            .shared
            .requestAsDict(AuthRouter.config)
            .trackActivity(self.activityIndicator)
            .trackError(self.errorTracker)
            // V11.1.15 (Build 5 — Guideline 2.1(a) fix):
            // Hard timeout on the /api/all-config request. Without this,
            // a hung network (e.g. App Review's network proxy slowing
            // responses) leaves the loading spinner running indefinitely.
            // 30s is generous enough for cold-start TLS handshakes on
            // cellular but short enough that the user sees a result.
            // On timeout, propagate the error so the existing onError
            // path routes to login (matching the network-error fallback).
            .timeout(.seconds(30), scheduler: MainScheduler.instance)
            .catch({ (error) -> Observable<[[String: Any]]> in
                print("[Remote Config] fetchConfigs failed: \(error.localizedDescription)")
                return .error(error)
            })
    }
    
    private func fetchProfileInfo() -> Observable<ProfileInfoM> {
        return self.useCase
            .getProfileInfo()
            .asDriver(onErrorJustReturn: ProfileInfoM.init(id: nil, email: "", avatar: "", name: "", state: "", memberPlan: .babybarJun, memberPlanSimple: 0, membership: "", lastSectionName: "", points: 0, phone: "", essayCount: 0, mptCount: 0, isTutor: false, isEmailZoom: false, currentMixedMbeSection: nil, currentDraftingSectionId: nil, currentCounselingSectionId: nil, currentNgSptSectionId: nil, currentNgLrptSectionId: nil, currentNgMcq1ChoiceSectionId: nil, currentNgMcq2ChoiceSectionId: nil, currentDraftingSectionName: nil, currentCounselingSectionName: nil, currentNgSptSectionName: nil, currentNgLrptSectionName: nil, currentNgMcq1ChoiceSectionName: nil, currentNgMcq2ChoiceSectionName: nil))
            .asObservable()
    }
}
