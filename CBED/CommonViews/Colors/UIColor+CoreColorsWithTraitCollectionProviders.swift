//
//  UIColor+CoreColorsWithTraitCollectionProviders.swift
//  CBED
//
//  Created by Jimmy Hoang on 26/06/2021.
//

import UIKit

extension UIColor {
    func cgColor(for provider: TraitCollectionProvider) -> CGColor {
        let traitCollection = provider.traitCollection
        return backwardsCompatibleResolvedColor(with: traitCollection).cgColor
    }

    func ciColor(for provider: TraitCollectionProvider) -> CIColor {
        let traitCollection = provider.traitCollection
        return backwardsCompatibleResolvedColor(with: traitCollection).ciColor
    }
}
