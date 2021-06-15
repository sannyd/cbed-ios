//
//  UICollectionView+.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import Foundation
import RxSwift
import Alamofire

extension UICollectionView {
    func rxModelSelected<T>() -> Observable<T> {
        return rx
            .modelSelected(T.self)
            .asObservable()
    }
}
