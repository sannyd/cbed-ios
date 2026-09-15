//
//  ScoreCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 7/25/21.
//

import UIKit

class ScoreCell: UICollectionViewCell, CellType {
    static var cellHeight: CGFloat {
        return 80
    }
    
    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 20 - 20
    }
    
    typealias T = ScoreM
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var labelUserID: UILabel!
    @IBOutlet weak var labelUserPosition: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func populateData(_ data: ScoreM) {
        if IsEnableLogin {
            profileImageView.loadImage(with: data.avatar, placeholder: #imageLiteral(resourceName: "img_user_placeholder"))
        } else {
            profileImageView.image = #imageLiteral(resourceName: "img_user_placeholder")
        }

        labelUserID.text = "ID - \(data.id)"

        if data.isEssay {
            // Essays chip selected — show the user's essay count prominently.
            labelUserPosition.text = "\(data.essaysCount)"
            labelUserPosition.textColor = Constants.PrimaryTextColor
        } else if data.isMpt {
            // M/PTs chip selected — show the user's M/PT count prominently.
            labelUserPosition.text = "\(data.mptCount)"
            labelUserPosition.textColor = Constants.PrimaryTextColor
        } else if let displayText = data.displayText, !displayText.isEmpty {
            // A non-default section chip is selected; the view model has
            // populated `displayText` with the per-section text to render
            // (e.g. "MBE: Level 7 - Property", "NG 1-Choice: Level 3").
            labelUserPosition.text = displayText
            labelUserPosition.textColor = Constants.PrimaryTextColor
        } else {
            // Default ('All') — show the user's MBE level chip with the
            // existing color helper. The optional is unwrapped here with
            // `?? "N/A"` so Swift's `Optional(...)` debug description
            // never leaks into the UI.
            let fallback = data.lastSectionName ?? "N/A"
            labelUserPosition.applyScoreboardLevelColor(for: fallback)
        }

    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.setRoundShape()
    }
}
