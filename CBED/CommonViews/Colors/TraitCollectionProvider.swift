//
//  TraitCollectionProvider.swift
//  CBED
//
//  Created by Jimmy Hoang on 26/06/2021.
//

import UIKit

protocol TraitCollectionProvider {
    var traitCollection: UITraitCollection { get }
}

extension UIView: TraitCollectionProvider { }
extension UIViewController: TraitCollectionProvider { }
