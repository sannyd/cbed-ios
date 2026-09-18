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
        // V11.1.10: 145pt = 29pt above card (where the upper half of
        // the 58pt elevated badge sits) + 112pt card + 4pt bottom
        // padding.
        return 145
    }

    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // V11.1.12: badge is now a sibling of cardView in contentView
        // (moved out of cardView in XIB), so the card's
        // CustomBorderView.drawCorner() can no longer clip the badge's
        // upper half. But the cell still needs to defensively keep
        // every layer in the badge path non-clipping on cold launch.
        clipsToBounds = false
        contentView.clipsToBounds = false
        cardView.clipsToBounds = false
        layer.masksToBounds = false
        contentView.layer.masksToBounds = false
        cardView.layer.masksToBounds = false

        // V11.1.10: apply the "elevated" circular badge styling so the
        // 58x58 badge sits visibly above the card with soft elevation.
        // SecondarySurfaceColor is the slightly-lighter purple in dark
        // mode and the light off-white in light mode — matches the
        // 11.0 visual hierarchy.
        circleView.backgroundColor = Constants.SecondarySurfaceColor
        // V11.1.10: drop-shadow under the badge for floating layered
        // depth (matches v11.0 reference). Set programmatically to
        // ensure exact spec values regardless of XIB runtime attrs.
        circleView.layer.shadowColor = UIColor.black.cgColor
        circleView.layer.shadowOpacity = 0.28
        circleView.layer.shadowOffset = CGSize(width: 0, height: 4)
        circleView.layer.shadowRadius = 6
        circleView.layer.masksToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // V11.1.12: collection views can re-enable contentView.clipsToBounds
        // when recycling cells, so enforce it explicitly on every layout
        // pass — for self, contentView, AND cardView, plus their layer
        // masksToBounds mirrors. The badge is a sibling of cardView so
        // it floats above the card; nothing in the layout should ever
        // clip the upper half of the badge on cold launch.
        clipsToBounds = false
        contentView.clipsToBounds = false
        cardView.clipsToBounds = false
        layer.masksToBounds = false
        contentView.layer.masksToBounds = false

        // V11.1.12: dynamic corner radius for the floating badge.
        // Computed from the actual layout-time bounds rather than the
        // XIB hard-coded 29pt, so any future size change can't leave
        // the badge out-of-round on cold launch.
        circleView.layer.cornerRadius = circleView.bounds.height / 2
        circleView.layer.masksToBounds = false

        // V11.1.12: ensure the badge stays on top of the card after
        // any cell-recycle that might have re-attached it in the back.
        contentView.bringSubviewToFront(circleView)
    }

    func populateData(_ data: LevelM) {
        labelName.text = data.name
    }
}
