//
//  BaseNibView.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 12/20/19.
//  Copyright © 2019 Advesa. All rights reserved.
//

import UIKit

class BaseNibView: UIView {
    var contentView: UIView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func loadNib(nibName: String) -> UIView {
        let bundle = Bundle(for: type(of: self))
        guard let contentView: UIView = bundle.loadNibNamed(nibName, owner: self, options: nil)!.first as? UIView else {
            return UIView(frame: frame)
        }
        return contentView
    }
    
    func addConstraintsWithFormat(format: String, views: UIView...) {
        var viewsDictionary = [String: UIView]()
        for (index, view) in views.enumerated() {
            let key = "v\(index)"
            viewsDictionary[key] = view
            view.translatesAutoresizingMaskIntoConstraints = false
        }
        addConstraints(NSLayoutConstraint.constraints(withVisualFormat: format, options: NSLayoutConstraint.FormatOptions(), metrics: nil, views: viewsDictionary))
    }
    
    func loadContentViewWithNib(nibName: String) {
        backgroundColor = UIColor.clear
        if contentView == nil {
            contentView = self.loadNib(nibName: nibName)
            contentView?.frame = bounds
            contentView?.backgroundColor = .clear
            addSubview(contentView!)
            addConstraintsWithFormat(format: "H:|[v0]|", views: contentView!)
            addConstraintsWithFormat(format: "V:|[v0]|", views: contentView!)
        }
    }
}
