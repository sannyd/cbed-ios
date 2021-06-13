//
//  UIView+.swift
//  CBED
//
//  Created by Jimmy Hoang on 12/06/2021.
//

import UIKit
import RxSwift
import RxGesture

extension UIView {
    static func nib() -> UINib {
        return UINib(nibName: nibName(), bundle: nil)
    }
    
    static func nibName() -> String {
        return String(describing: self)
    }
    
    static func fromNib() -> UIView {
        return Bundle.main.loadNibNamed(String(describing: self), owner: nil, options: nil)![0] as! UIView
    }
    
    static func fromNib(nibName: String) -> UIView {
        return Bundle.main.loadNibNamed(nibName, owner: nil, options: nil)![0] as! UIView
    }
    
    func setCornerRadius(radius: CGFloat, borderWidth: CGFloat? = nil, borderColor: UIColor? = nil) {
        self.layer.cornerRadius = radius
        
        if let borderWidth = borderWidth {
            self.layer.borderWidth = borderWidth
        }
        
        if let borderColor = borderColor {
            self.layer.borderColor = borderColor.cgColor
        }
    }
    
    func setShadow(color: UIColor, opacity: Float, offSet: CGSize, radius: CGFloat) {
        layer.shadowColor = color.cgColor
        layer.shadowOpacity = opacity
        layer.shadowOffset = offSet
        layer.shadowRadius = radius / 2
    }
    
    func roundCorners(_ corners: CACornerMask, radius: CGFloat) {
        if #available(iOS 11, *) {
            self.layer.cornerRadius = radius
            self.layer.maskedCorners = corners
        } else {
            var cornerMask = UIRectCorner()
            if corners.contains(.layerMinXMinYCorner) {
                cornerMask.insert(.topLeft)
            }
            if corners.contains(.layerMaxXMinYCorner) {
                cornerMask.insert(.topRight)
            }
            if corners.contains(.layerMinXMaxYCorner) {
                cornerMask.insert(.bottomLeft)
            }
            if corners.contains(.layerMaxXMaxYCorner) {
                cornerMask.insert(.bottomRight)
            }
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: cornerMask, cornerRadii: CGSize(width: radius, height: radius))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
        }
    }
    
    func setRoundShape() {
        self.layer.masksToBounds = true
        self.layer.cornerRadius = self.bounds.height / 2
    }
}

// MARK: Rx
extension UIView {
    var rxGestureTapped: Observable<Void> {
        return rx
            .tapGesture()
            .when(.recognized)
            .mapToVoid()
    }
}
