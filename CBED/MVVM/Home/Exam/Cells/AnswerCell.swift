//
//  AnswerCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 19/06/2021.
//

import UIKit

class AnswerCell: UICollectionViewCell,
                  CellType {
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var radioImageView: UIImageView!
    
    typealias T = AnswerM
    
    var cellHeight: CGFloat {
        return 70
    }
    
    private var labelAddressHeight: CGFloat {
        let labelWidth: CGFloat = UIScreen.main.bounds.width - 10 - 10 - 16 - 16 - 8 - 8 - 18
        let maxLabelSize = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        let titleLabelSize = labelText.sizeThatFits(maxLabelSize)
        return titleLabelSize.height
    }
    
    var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }
    
    func populateData(_ data: AnswerM) {
        
    }

}
