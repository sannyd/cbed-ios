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
    @IBOutlet weak var cardView: CustomBorderView!
    @IBOutlet weak var circleView: CustomBorderView!

    typealias T = LevelM

    static var cellHeight: CGFloat {
        // V11.1.5: 200pt to host the elevated circular badge that
        // straddles the card's top edge — the badge hangs -40pt
        // above the card top and 40pt below, so 40pt of empty
        // space above the card is required (200 = 40 above + 150
        // card + 10 bottom padding).
        return 200
    }

    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // V11.1.5: apply the "elevated" circular badge styling so the
        // badge sits visibly above the card. SecondarySurfaceColor is
        // the slightly-lighter purple in dark mode and the light
        // off-white in light mode — matches the 11.0 visual hierarchy.
        circleView.backgroundColor = Constants.SecondarySurfaceColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // V11.1.5: CustomBorderView.drawCorner() (called from
        // layoutSubviews) sets clipsToBounds = true on any view with
        // rounded corners. The card here is rounded (borderRadius=10,
        // all 4 corners) AND it hosts the circular badge that hangs
        // 40pt above its top edge. With clipsToBounds=true the upper
        // half of the badge gets clipped by the card's rectangular
        // bounds. Force clipsToBounds=false after super has run so
        // the badge renders fully.
        cardView.clipsToBounds = false
    }

    func populateData(_ data: LevelM) {
        labelName.text = data.name
    }
}
