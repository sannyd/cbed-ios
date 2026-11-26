//
//  ActivityIndicator.swift
//  MGArchitecture
//
//  Created by Tuan Truong on 4/1/19.
//  Copyright © 2019 Sun Asterisk. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

open class ActivityIndicator: SharedSequenceConvertibleType {
    public typealias Element = Bool
    public typealias SharingStrategy = DriverSharingStrategy
    
    private let _lock = NSRecursiveLock()
    private let _variable = BehaviorRelay<Bool>(value: false)
    private let _loading: SharedSequence<SharingStrategy, Bool>
    
    public init() {
        _loading = _variable.asDriver()
            .distinctUntilChanged()
    }
    
    fileprivate func trackActivityOfObservable<O: ObservableConvertibleType>(_ source: O) -> Observable<O.Element> {
        return source.asObservable()
            .do(onNext: { _ in
                self.sendStopLoading()
            }, onError: { _ in
                self.sendStopLoading()
            }, onCompleted: {
                self.sendStopLoading()
            }, onSubscribe: subscribed,
               onDispose: {
                // V261125.1 — a disposed subscription must also stop loading.
                //
                // The other three handlers only fire when the source
                // actually emits, errors, or completes. If the
                // subscription is disposed BEFORE any of those happen, the
                // indicator stays `true` forever.
                //
                // That is not a theoretical case: `flatMapLatest` disposes
                // the previous inner observable the moment a new outer
                // value arrives. `ExamViewModel` drives its save through
                // exactly that shape
                // (`saveResultTrigger.flatMapLatest(saveResult(...))`), so
                // a second trigger disposed the in-flight save without
                // ever completing it.
                //
                // The stranded `true` value drives
                // `LoadingIndicatorView.rx.isAnimating`, which calls
                // `LoadingIndicatorView.show()` — a full-window overlay
                // that absorbs EVERY touch. The student is left with a
                // live-looking screen that responds to nothing, and the
                // overlay follows them to the next screen because it is
                // attached to the window, not the view controller.
                //
                // `onDispose` fires for a normal completion as well as for
                // an early disposal, so `sendStopLoading()` here is safe
                // and idempotent (it just re-accepts `false`).
                self.sendStopLoading()
            })
    }
    
    private func subscribed() {
        _lock.lock()
        _variable.accept(true)
        _lock.unlock()
    }
    
    private func sendStopLoading() {
        _lock.lock()
        _variable.accept(false)
        _lock.unlock()
    }
    
    open func asSharedSequence() -> SharedSequence<SharingStrategy, Element> {
        return _loading
    }
}

extension ObservableConvertibleType {
    public func trackActivity(_ activityIndicator: ActivityIndicator) -> Observable<Element> {
        return activityIndicator.trackActivityOfObservable(self)
    }
}
