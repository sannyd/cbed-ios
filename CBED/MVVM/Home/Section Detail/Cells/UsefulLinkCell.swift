//
//  UsefulLinkCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import UIKit

class UsefulLinkCell: UICollectionViewCell, CellType {
    typealias T = UsefulLink
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelLink: UILabel!

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
