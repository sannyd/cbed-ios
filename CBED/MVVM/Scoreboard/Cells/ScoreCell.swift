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
        
        labelUserID.text = "\(data.id)"
        labelUserPosition.text = "\(data.lastSectionName ?? "N/A")"
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        profileImageView.setRoundShape()
    }
}
