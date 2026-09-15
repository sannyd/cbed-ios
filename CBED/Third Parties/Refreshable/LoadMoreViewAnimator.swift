//
//  LoadMoreAnimator.swift
//  Refreshable
//
//  Created by Hoangtaiki on 7/25/18.
//  Copyright © 2018 toprating. All rights reserved.
//

import UIKit

open class LoadMoreAnimator: UIView, LoadMoreDelegate {

    open var spinner = UIActivityIndicatorView(style: .gray)

    override init(frame: CGRect) {
        super.init(frame: frame)
        autoresizingMask = .flexibleWidth

        addSubview(spinner)
        spinner.isHidden = true
    }

    public required init(coder aDecoder: NSCoder) {
        // CBED: never created via Storyboard/NIB, but be safe for state restoration.
        // super.init(coder:) is failable; we trap if it fails. In production this
        // path should never execute since these animators are not in any NIB.
        assertionFailure("init(coder:) is not supported — use init(frame:)")
        guard let _ = super.init(coder: aDecoder) else {
            fatalError("super.init(coder:) returned nil — NIB coder should never reach here")
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()

        spinner.center = CGPoint(x: frame.size.width * 0.5, y: frame.size.height * 0.5)
    }

    open func loadMoreAnimationDidStart(view: LoadMoreView) {
        spinner.isHidden = false
        spinner.startAnimating()
    }

    open func loadMoreAnimationDidEnd(view: LoadMoreView) {
        spinner.isHidden = true
        spinner.stopAnimating()

    }
}
