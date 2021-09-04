//
//  LevelViewModel.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import RxSwift
import RxCocoa

// MARK: Input + Output
extension LevelViewModel {
    struct Input {
        let firstLoadTrigger: Observable<Void>
        let viewWillAppear: Observable<Void>
        let levelTapped: Observable<LevelM>
        let searchViewTapped: Observable<Void>
        let unlockViewTapped: Observable<Void>
    }
    
    struct Output {
        let levels: Driver<[CommonCollectionViewSection<LevelM>]>
        let userProfile: Observable<ProfileInfoM?>
        let isReloading: Driver<Bool>
        let isLoading: Driver<Bool>
        let error: Driver<Error>
    }
}

struct LevelViewModel: ViewModel {
    let useCase: LevelUseCaseType
    let navigator: LevelNavigatorType
    
    private let errorTracker = ErrorTracker()
    private let activityIndicator = ActivityIndicator()
    private let loadindIndicator = ActivityIndicator()
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        let levels = input
            .firstLoadTrigger
            .flatMapLatest(fetchAllLevels)
            .map { items -> [LevelM] in
                if !IsEnableLogin {
                    if let currentMembership = CurrentMembershipType {
                        switch currentMembership {
                        case .ProBarFeb,
                             .ProBarJul:
                            return items
                        case .BabyBarJun,
                             .BabyBarOct:
                            return items.filter { $0.id != 10 }
                        }
                    } else {
                        return items.filter { $0.id == 8 }
                    }
                } else {
                    return items
                }
            }
            .map { [CommonCollectionViewSection(items: $0)] }
        
        let userProfile = input
            .viewWillAppear
            .map { _ in Storage.profileInfo }
        
        input
            .levelTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToSectionsVC(level:))
            .disposed(by: disposeBag)
        
        input
            .searchViewTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToSearchVC)
            .disposed(by: disposeBag)
        
        input
            .unlockViewTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: navigator.pushToInAppPurchaseVC)
            .disposed(by: disposeBag)
        
        return Output(levels: levels.asDriver(onErrorJustReturn: []),
                      userProfile: userProfile,
                      isReloading: activityIndicator.asDriver(),
                      isLoading: loadindIndicator.asDriver(),
                      error: errorTracker.asDriver())
    }
    
    func fetchAllLevels() -> Observable<[LevelM]> {
        return self.useCase
            .getAllLevels()
            .trackError(errorTracker)
            .trackActivity(activityIndicator)
            .catch { _ in
                return .never()
            }
    }
    
    private func fetchSectionDetailByID(id: Int) -> Observable<SectionDetailM> {
        return self.useCase
            .getSectionByID(id: id)
            .trackError(errorTracker)
            .trackActivity(loadindIndicator)
            .catch { _ in
                return .never()
            }
    }
}
