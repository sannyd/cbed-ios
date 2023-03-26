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
    
    func populateData(_ data: SelectableAnswer) {
        if data.isSelected {
            if data.isCheck {
                if data.answer.isCorrect {
                    backgroundContainerView.backgroundColor = Constants.PrimaryBlue
                    backgroundContainerView.shadowColor = Constants.PrimaryBlue
                    labelText.textColor = .white
                    radioImageView.image = #imageLiteral(resourceName: "img_answer_selected")
                } else {
                    backgroundContainerView.backgroundColor = Constants.ColorE0293F
                    backgroundContainerView.shadowColor = Constants.ColorE0293F
                    labelText.textColor = Constants.PrimaryTextColor
                    radioImageView.image = #imageLiteral(resourceName: "img_answer_unselected")
                }
            } else {
                backgroundContainerView.backgroundColor = Constants.PrimaryBlue
                backgroundContainerView.shadowColor = Constants.PrimaryBlue
                labelText.textColor = .white
                radioImageView.image = #imageLiteral(resourceName: "img_answer_selected")
            }
            
        } else {
            if data.isEliminated {
                backgroundContainerView.backgroundColor = .gray
                backgroundContainerView.shadowColor = .black
                labelText.textColor = Constants.PrimaryTextColor
                radioImageView.image = nil
            } else {
                backgroundContainerView.backgroundColor = Constants.CellColor
                backgroundContainerView.shadowColor = .black
                labelText.textColor = Constants.PrimaryTextColor
                radioImageView.image = #imageLiteral(resourceName: "img_answer_unselected")
            }
        }
        
        labelText.text = data.answer.content
    }

    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: UIScreen.main.bounds.width - 20 - 20 - 16 - 16, height: 0)
        layoutAttributes.frame.size = contentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .fittingSizeLevel)
        return layoutAttributes
    }
}
