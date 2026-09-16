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
    @IBOutlet weak var pillarImageView: UIImageView!
    
    typealias T = LevelM

    static var cellHeight: CGFloat {
        // V11.1: bumped 162 -> 200 to fit the now-INSIDE-circle icon
        // (14pt top padding + 80pt circle + 14pt gap + label stack + 8pt
        // bottom padding). Previously the circle hung -40pt above the
        // card and the icon's top was clipped by the card's corner-
        // rounding clipsToBounds.
        return 200
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
