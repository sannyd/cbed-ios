//
//  CDBorderButtonV.swift
//  Cantec Driver
//
//  Created by Duy Nguyen on 09/07/2019.
//  Copyright © 2019 Advesa. All rights reserved.
//

import UIKit

class CustomBorderButton: UIButton {
    @IBInspectable var borderRadius: CGFloat = 0 {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var borderColor: UIColor = .clear {
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
    @IBInspectable var disabledBackgroundColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }
    @IBInspectable var enabledBackgroundColor: UIColor = UIColor.clear {
        didSet {
            updateView()
        }
    }
    
    @IBInspectable var imageAlpha: CGFloat = 1 {
           didSet {
               updateView()
           }
       }

    override open var isEnabled: Bool {
        didSet {
            updateView()
        }
    }
    
    func updateView() {
        layer.cornerRadius = borderRadius
        layer.shadowColor = shadowColor.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowRadius = shadowRadius
        layer.shadowOffset = shadowOffset
        if isEnabled {
            backgroundColor = enabledBackgroundColor
        } else {
            backgroundColor = disabledBackgroundColor
        }
        layer.borderColor = borderColor.cgColor
        layer.borderWidth = borderWidth
    }
}
