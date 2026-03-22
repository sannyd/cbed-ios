//
//  CDLoadingIndicatorView.swift
//  CantecCourier
//
//  Created by Jimmy Hoang on 10/28/20.
//

import UIKit
import RxSwift
import RxCocoa

class LoadingIndicatorView: NSObject {
    
    static var currentOverlay: UIView?
    static var currentOverlayTarget: UIView?
    static var currentLoadingText: String?
    
    private let indicator = CAShapeLayer()
    private let animator = MaterialActivityIndicatorAnimator()
    
    static func show() {
        guard let currentMainWindow = UIApplication.shared.keyWindow else {
            print("No main window.")
            return
        }
        show(currentMainWindow)
    }
    
    static func show(_ loadingText: String) {
        guard let currentMainWindow = UIApplication.shared.keyWindow else {
            print("No main window.")
            return
        }
        show(currentMainWindow, loadingText: loadingText)
    }
    
    static func show(_ overlayTarget: UIView) {
        show(overlayTarget, loadingText: nil)
    }
    
    static func show(_ overlayTarget: UIView,
                     loadingText: String?,
                     color: UIColor = Constants.PrimaryBlue) {
        // Clear it first in case it was already shown
        hide()
        
        // Create the overlay
        let overlay = UIView()
        overlay.alpha = 1
        overlay.backgroundColor = UIColor.clear
        overlay.translatesAutoresizingMaskIntoConstraints = false
        overlayTarget.addSubview(overlay)
        overlayTarget.bringSubviewToFront(overlay)
        
        overlay.widthAnchor.constraint(equalTo: overlayTarget.widthAnchor).isActive = true
        overlay.heightAnchor.constraint(equalTo: overlayTarget.heightAnchor).isActive = true
        
        // Create and animate the activity indicator
        let indicator = MaterialActivityIndicatorView()
        indicator.color = color
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.startAnimating()
        overlay.addSubview(indicator)
        
        indicator.centerXAnchor.constraint(equalTo: overlay.centerXAnchor).isActive = true
        indicator.centerYAnchor.constraint(equalTo: overlay.centerYAnchor).isActive = true
        indicator.heightAnchor.constraint(equalToConstant: 60).isActive = true
        indicator.widthAnchor.constraint(equalToConstant: 60).isActive = true
        
        // Create label
        if let textString = loadingText {
            let label = UILabel()
            label.text = textString
            label.textColor = .label
            overlay.addSubview(label)
            label.translatesAutoresizingMaskIntoConstraints = false
            label.topAnchor.constraint(equalTo: indicator.bottomAnchor, constant: 16).isActive = true
            label.centerXAnchor.constraint(equalTo: indicator.centerXAnchor).isActive = true
        }
        
        // Animate the overlay to show
//        UIView.beginAnimations(nil, context: nil)
//        UIView.setAnimationDuration(0.25)
//        overlay.alpha = overlay.alpha > 0 ? 0 : 0.6
//        UIView.commitAnimations()
        
        currentOverlay = overlay
        currentOverlayTarget = overlayTarget
        currentLoadingText = loadingText
    }
    
    static func hide() {
        if currentOverlay != nil {
            currentOverlay?.removeFromSuperview()
            currentOverlay =  nil
            currentLoadingText = nil
            currentOverlayTarget = nil
        }
    }
}

class MaterialActivityIndicatorAnimator {
    enum Animation: String {
        var key: String {
            return rawValue
        }

        case spring = "material.indicator.spring"
        case rotation = "material.indicator.rotation"
    }

    public func addAnimation(to layer: CALayer) {
        layer.add(rotationAnimation(), forKey: Animation.rotation.key)
        layer.add(springAnimation(), forKey: Animation.spring.key)
    }

    public func removeAnimation(from layer: CALayer) {
        layer.removeAnimation(forKey: Animation.rotation.key)
        layer.removeAnimation(forKey: Animation.spring.key)
    }
}

extension MaterialActivityIndicatorAnimator {
    private func rotationAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(key: .rotationZ)
        animation.duration = 4
        animation.fromValue = 0
        animation.toValue = (2.0 * .pi)
        animation.repeatCount = .infinity

        return animation
    }

    private func springAnimation() -> CAAnimationGroup {
        let animation = CAAnimationGroup()
        animation.duration = 1.5
        animation.animations = [
            strokeStartAnimation(),
            strokeEndAnimation(),
            strokeCatchAnimation(),
            strokeFreezeAnimation()
        ]
        animation.repeatCount = .infinity

        return animation
    }

    private func strokeStartAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(key: .strokeStart)
        animation.duration = 1
        animation.fromValue = 0
        animation.toValue = 0.15
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        return animation
    }

    private func strokeEndAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(key: .strokeEnd)
        animation.duration = 1
        animation.fromValue = 0
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        return animation
    }

    private func strokeCatchAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(key: .strokeStart)
        animation.beginTime = 1
        animation.duration = 0.5
        animation.fromValue = 0.15
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        return animation
    }

    private func strokeFreezeAnimation() -> CABasicAnimation {
        let animation = CABasicAnimation(key: .strokeEnd)
        animation.beginTime = 1
        animation.duration = 0.5
        animation.fromValue = 1
        animation.toValue = 1
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)

        return animation
    }
}

class MaterialActivityIndicatorView: UIView {
    var color: UIColor = Constants.PrimaryBlue {
        didSet {
            indicator.strokeColor = color.cgColor
        }
    }

    var lineWidth: CGFloat = 2.0 {
        didSet {
            indicator.lineWidth = lineWidth
            setNeedsLayout()
        }
    }

    private let indicator = CAShapeLayer()
    private let animator = MaterialActivityIndicatorAnimator()

    private var isAnimating = false

    convenience init() {
        self.init(frame: .zero)
        self.setup()
    }

    override public init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }

    private func setup() {
        indicator.strokeColor = color.cgColor
        indicator.fillColor = nil
        indicator.lineWidth = lineWidth
        indicator.strokeStart = 0.0
        indicator.strokeEnd = 0.0
        layer.addSublayer(indicator)
    }
}

extension MaterialActivityIndicatorView {
    override public var intrinsicContentSize: CGSize {
        return CGSize(width: 24, height: 24)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        indicator.frame = bounds

        let diameter = bounds.size.min - indicator.lineWidth
        let path = UIBezierPath(center: bounds.center, radius: diameter / 2)
        indicator.path = path.cgPath
    }
}

extension MaterialActivityIndicatorView {
    public func startAnimating() {
        guard !isAnimating else { return }

        animator.addAnimation(to: indicator)
        isAnimating = true
    }

    public func stopAnimating() {
        guard isAnimating else { return }

        animator.removeAnimation(from: indicator)
        isAnimating = false
    }
}

extension Reactive where Base: LoadingIndicatorView {
   static var isAnimating: Binder<Bool> {
      return Binder(UIApplication.shared) { _, isVisible in
         if isVisible {
            LoadingIndicatorView.show()
         } else {
            LoadingIndicatorView.hide()
         }
      }
   }
}
