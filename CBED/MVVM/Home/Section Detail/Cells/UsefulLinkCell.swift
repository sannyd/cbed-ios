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

    var cellHeight: CGFloat {
        return 70
    }
    
    var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }
    
    func populateData(_ data: UsefulLink) {
        switch data.type {
        case .video:
            avatarImageView.image = nil
            labelName.text = "Video link"
            labelLink.text = data.url
        case .pdf:
            avatarImageView.image = #imageLiteral(resourceName: "img_pdf")
            labelName.text = "PDF"
            labelLink.text = data.url
        }
    }
}
