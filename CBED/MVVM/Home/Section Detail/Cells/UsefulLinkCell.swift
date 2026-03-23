//
//  UsefulLinkCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import UIKit

class UsefulLinkCell: UICollectionViewCell, CellType {
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelLink: UILabel!
    
    typealias T = UsefulLink

    static var cellHeight: CGFloat {
        return 70
    }
    
    static  var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        labelName.applyAppFontScaling()
        labelLink.applyAppFontScaling()
    }
    
    func populateData(_ data: UsefulLink) {
        switch data.type {
        case .video:
            avatarImageView.image = #imageLiteral(resourceName: "img_link")
            let strings = data.url.split(separator: ",")
            let title = strings.first ?? ""
            labelName.text = String(title)
            labelLink.text = data.url
        case .pdf:
            avatarImageView.image = #imageLiteral(resourceName: "img_link")
            let strings = data.url.split(separator: ",")
            let title = strings.first ?? ""
            labelName.text = String(title)
            labelLink.text = data.url
        }
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: UIScreen.main.bounds.width - 16 - 16, height: 0)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return layoutAttributes
    }
}
