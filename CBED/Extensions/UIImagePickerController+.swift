//
//  UIImagePickerController+.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/07/2021.
//

import UIKit
import RxSwift
import RxCocoa

#if os(iOS)
    
    import RxSwift
    import RxCocoa
    import UIKit

    extension Reactive where Base: UIImagePickerController {

        /**
         Reactive wrapper for `delegate` message.
         */
        public var didFinishPickingMediaWithInfo: Observable<[UIImagePickerController.InfoKey : AnyObject]> {
            return delegate
                .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerController(_:didFinishPickingMediaWithInfo:)))
                .map({ (a) in
                    return try castOrThrow(Dictionary<UIImagePickerController.InfoKey, AnyObject>.self, a[1])
                })
        }

        /**
         Reactive wrapper for `delegate` message.
         */
        public var didCancel: Observable<()> {
            return delegate
                .methodInvoked(#selector(UIImagePickerControllerDelegate.imagePickerControllerDidCancel(_:)))
                .map {_ in () }
        }
        
    }
    
#endif

private func castOrThrow<T>(_ resultType: T.Type, _ object: Any) throws -> T {
    guard let returnValue = object as? T else {
        throw RxCocoaError.castingError(object: object, targetType: resultType)
    }
    
    return returnValue
}

extension Reactive where Base: UIImagePickerController {
    static func createAndPresent(from parent: UIViewController?, animated: Bool = true, configureImagePicker: @escaping (UIImagePickerController) throws -> Void = { x in }) -> Observable<[UIImagePickerController.InfoKey: Any]> {
        return Observable.create { [weak parent] observer in
            let imagePicker = UIImagePickerController()
            let dismissDisposable = imagePicker.rx
                .didCancel
                .subscribe(onNext: { [weak imagePicker] _ in
                    guard let imagePicker = imagePicker else {
                        return
                    }
                    imagePicker.dismiss(animated: true)
                })
            let eventDisposable = imagePicker.rx.didFinishPickingMediaWithInfo
                .subscribe(onNext: { [weak imagePicker] info in
                    guard let imagePicker = imagePicker else {
                        return
                    }
                    observer.on(.next(info))
                    imagePicker.dismiss(animated: true)
                })
            
            do {
                try configureImagePicker(imagePicker)
            } catch {
                observer.on(.error(error))
                return Disposables.create()
            }
            
            guard let parent = parent else {
                observer.on(.completed)
                return Disposables.create()
            }
            
            parent.present(imagePicker, animated: animated, completion: nil)
            
            return Disposables.create(dismissDisposable, eventDisposable, Disposables.create {
                imagePicker.dismiss(animated: true)
            })
        }
    }
}
