//
//  AnswerCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 19/06/2021.
//

import UIKit

struct SelectableAnswer: Equatable {
    var isSelected: Bool
    var isCheck: Bool
    var isEliminated: Bool
    var answer: AnswerM
}

class AnswerCell: UICollectionViewCell,
                  CellType {
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var radioImageView: UIImageView!
    @IBOutlet weak var backgroundContainerView: CustomBorderView!
    
    typealias T = SelectableAnswer
    
    static var cellHeight: CGFloat {
        return 0
    }

    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        labelText.scaledFont(style: .body)
    }
    
    private var labelTextHeight: CGFloat {
        let labelWidth: CGFloat = UIScreen.main.bounds.width - 16 - 16 - 8 - 35
        let maxLabelSize = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        let titleLabelSize = labelText.sizeThatFits(maxLabelSize)
        return titleLabelSize.height
    }
    
    var cellHeight: CGFloat {
        return labelTextHeight + 8 + 8
    }
    
    func populateData(_ data: SelectableAnswer) {
        let eliminatedColor = UIColor.systemGray
        if data.isSelected {
            if data.isCheck {
                backgroundContainerView.backgroundColor = data.isEliminated ? eliminatedColor : Constants.ColorE0293F
                backgroundContainerView.shadowColor = Constants.ColorE0293F
                labelText.textColor = .white
                radioImageView.image = #imageLiteral(resourceName: "img_answer_unselected")
            } else {
                backgroundContainerView.backgroundColor = data.isEliminated ? eliminatedColor : Constants.PrimaryBlue
                backgroundContainerView.shadowColor = Constants.PrimaryBlue
                labelText.textColor = .white
                radioImageView.image = #imageLiteral(resourceName: "img_answer_selected")
            }
        } else {
            backgroundContainerView.backgroundColor = data.isEliminated ? eliminatedColor : Constants.CellColor
            backgroundContainerView.shadowColor = Constants.CardShadowColor
            labelText.textColor = Constants.PrimaryTextColor
            radioImageView.image = #imageLiteral(resourceName: "img_answer_unselected")
        }
        
        labelText.text = data.answer.content
    }
}
