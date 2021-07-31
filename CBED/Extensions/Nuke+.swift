//
//  Nuke+Extension.swift
//  Cantec Driver
//
//  Created by Jimmy Hoang on 11/5/19.
//  Copyright © 2019 Advesa. All rights reserved.
//

import UIKit
import Nuke

protocol NukeExtension {
    func loadImage(with url: String?,
                   placeholder: UIImage?)
}
    
extension NukeExtension where Self: ImageDisplayingView {
    func loadImage(with url: String?,
                   placeholder: UIImage?) {
       
        guard let url = url,
            !url.isEmpty,
            let imageUrl = URL(string: url) else {
                nuke_display(image: placeholder)
            return
        }
        let request = ImageRequest(url: imageUrl)
        Nuke.loadImage(with: request, into: self)
    }
}

extension UIButton: Nuke_ImageDisplaying {
    /// Displays an image.
    public func nuke_display(image: PlatformImage?) {
        self.setImage(image, for: .normal)
    }
}

extension UIImageView: NukeExtension {}
extension UIButton: NukeExtension {}
