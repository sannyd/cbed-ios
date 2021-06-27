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
    
    typealias T = SectionM
    
    static var cellHeight: CGFloat {
        return 80
    }
    
    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }
    
    func populateData(_ data: SectionM) {
        labelTitle.text = data.name
        sectionImageView.image = #imageLiteral(resourceName: "img_tort")
//        labelSubtitle.text = data.
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sectionImageView.setRoundShape()
    }
}
