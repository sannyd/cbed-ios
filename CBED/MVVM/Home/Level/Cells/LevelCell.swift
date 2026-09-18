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
        // V11.1.11: keep the upper half of the floating badge visible
        // on cold launch. The badge straddles the card's top edge
        // (centerY = card.top) with ~28pt of its upper half sitting in
        // the cell's gap above the card. UICollectionViewCell clips
        // through contentView by default and the card's rounded
        // CustomBorderView runs drawCorner() on every layout pass,
        // both of which can clip the floating badge before the very
        // first pull-to-refresh layout pass settles. Disable clipping
        // on every layer that touches the badge path:
        //   - self (the cell itself)
        //   - contentView (collection-view cell container)
        //   - cardView (rounded card hosting the badge center)
        clipsToBounds = false
        contentView.clipsToBounds = false
        cardView.clipsToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // V11.1.8: CustomBorderView.drawCorner() (called from
        // layoutSubviews) sets clipsToBounds = true on any view with
        // rounded corners. The card here is rounded AND it hosts the
        // 56x56 circular badge whose center sits on the card's top
        // edge. With clipsToBounds=true the upper half of the badge
        // gets clipped by the card's rectangular bounds. Force
        // clipsToBounds=false after super has run so the badge
        // renders fully.
        // V11.1.11: same defense applied to self + contentView so the
        // badge is never clipped on cold launch (before any pull-to-
        // refresh layout pass settles the frames).
        clipsToBounds = false
        contentView.clipsToBounds = false
        cardView.clipsToBounds = false

        // V11.1.11: dynamic corner radius for the floating badge.
        // Computed from the actual layout-time bounds rather than the
        // XIB hard-coded 29pt, so any future size change can't leave
        // the badge out-of-round on cold launch.
        circleView.layer.cornerRadius = circleView.bounds.height / 2
        circleView.layer.masksToBounds = false
    }

    func populateData(_ data: LevelM) {
        labelName.text = data.name
    }
}
