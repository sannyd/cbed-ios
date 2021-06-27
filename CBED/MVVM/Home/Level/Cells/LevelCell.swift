//
//  LevelCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit

class LevelCell: UICollectionViewCell, CellType {
    @IBOutlet weak var labelName: UILabel!
    @IBOutlet weak var labelNumberOfQuestion: UILabel!
    
    typealias T = LevelM

    static var cellHeight: CGFloat {
        return 162
    }
    
    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func populateData(_ data: LevelM) {
        labelName.text = data.name
    }
}
