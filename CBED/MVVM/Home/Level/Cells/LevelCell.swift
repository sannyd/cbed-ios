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
        // V11.1.6: tight 124pt = 24pt above card (where the upper
        // half of the elevated badge sits) + 96pt card + 4pt bottom
        // padding. Badge is now 48x48 with centerY anchored to the
        // card's top edge, so only ~24pt of clearance is needed above
        // the card for the upper half to fit.
        return 124
    }

    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // V11.1.6: apply the "elevated" circular badge styling so the
        // badge sits visibly above the card. SecondarySurfaceColor is
        // the slightly-lighter purple in dark mode and the light
        // off-white in light mode — matches the 11.0 visual hierarchy.
        circleView.backgroundColor = Constants.SecondarySurfaceColor
        // V11.1.6: also disable clipping on the contentView itself so
        // the upper half of the badge (which sits in the 24pt gap
        // above the card) is not clipped by the cell boundary.
        contentView.clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // V11.1.6: CustomBorderView.drawCorner() (called from
        // layoutSubviews) sets clipsToBounds = true on any view with
        // rounded corners. The card here is rounded AND it hosts the
        // circular badge whose center sits on the card's top edge.
        // With clipsToBounds=true the upper half of the badge gets
        // clipped by the card's rectangular bounds. Force
        // clipsToBounds=false after super has run so the badge
        // renders fully.
        cardView.clipsToBounds = false
        contentView.clipsToBounds = false
    }

    func populateData(_ data: LevelM) {
        labelName.text = data.name
    }
}
