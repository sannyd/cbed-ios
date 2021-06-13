//
//  CustomBorderView.swift
//  CantecCentral
//
//  Created by Jimmy Hoang on 3/1/21.
//

import UIKit

class CustomBorderView: UIView {
    @IBInspectable var borderRadius: CGFloat = 0 {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var topLeft: Bool = false {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var topRight: Bool = false {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var bottomLeft: Bool = false {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var bottomRight: Bool = false {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var shadowColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var shadowOpacity: Float = 1.0 {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var shadowRadius: CGFloat = 0 {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var shadowOffset: CGSize = CGSize.zero {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var borderColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            updateView()
        }
    }
    
    func updateView() {
        drawCorner()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        drawCorner()
        self.layoutIfNeeded()
    }
    
    func drawCorner() {
        self.clipsToBounds = false
        var corners: CACornerMask = .init()
        if self.topLeft {
            corners.insert(.layerMinXMinYCorner)
        }
        if self.topRight {
            corners.insert(.layerMaxXMinYCorner)
        }
        if self.bottomLeft {
            corners.insert(.layerMinXMaxYCorner)
        }
        if self.bottomRight {
            corners.insert(.layerMaxXMaxYCorner)
        }

        self.layer.shadowColor = self.shadowColor.cgColor
        self.layer.shadowOpacity = self.shadowOpacity
        self.layer.shadowRadius = self.shadowRadius
        self.layer.shadowOffset = self.shadowOffset
        self.roundCorners(corners, radius: self.borderRadius)
        self.layer.borderColor = self.borderColor.cgColor
        self.layer.borderWidth = self.borderWidth
    }
}
