//
//  SectionCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import UIKit

class SectionCell: UICollectionViewCell, CellType {
    @IBOutlet weak var sectionImageView: UIImageView!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubtitle: UILabel!
    
    typealias T = SearchResultM
    
    static var cellHeight: CGFloat {
        return 80
    }
    
    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }
    
    func populateData(_ data: SearchResultM) {
        labelTitle.text = data.name
        labelSubtitle.text = data.subtitle
        if let imageURL = data.image {
            sectionImageView.loadImage(with: imageURL, placeholder: #imageLiteral(resourceName: "img_tort"))
        } else {
            sectionImageView.image = #imageLiteral(resourceName: "img_tort")
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sectionImageView.setRoundShape()
    }
}
