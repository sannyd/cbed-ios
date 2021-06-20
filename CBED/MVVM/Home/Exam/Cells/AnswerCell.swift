//
//  AnswerCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 19/06/2021.
//

import UIKit

struct SelectableAnswer: Equatable {
    var isSelected: Bool
    var answer: AnswerM
}

class AnswerCell: UICollectionViewCell,
                  CellType {
    @IBOutlet weak var labelText: UILabel!
    @IBOutlet weak var radioImageView: UIImageView!
    @IBOutlet weak var backgroundContainerView: CustomBorderView!
    
    typealias T = SelectableAnswer
    
    var cellHeight: CGFloat {
        return 0
    }

    var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 30 - 30
    }
    
    func populateData(_ data: SelectableAnswer) {
        if data.isSelected {
            if data.answer.isCorrect {
                backgroundContainerView.backgroundColor = Constants.Color295BE0
                backgroundContainerView.shadowColor = Constants.Color295BE0
                labelText.textColor = .white
                radioImageView.image = #imageLiteral(resourceName: "img_answer_selected")
            } else {
                backgroundContainerView.backgroundColor = Constants.ColorE0293F
                backgroundContainerView.shadowColor = Constants.ColorE0293F
                labelText.textColor = Constants.Color36343D
                radioImageView.image = #imageLiteral(resourceName: "img_answer_unselected")
            }
        } else {
            backgroundContainerView.backgroundColor = .white
            backgroundContainerView.shadowColor = .black
            labelText.textColor = Constants.Color36343D
            radioImageView.image = #imageLiteral(resourceName: "img_answer_unselected")
        }
        
        labelText.text = data.answer.content
    }

}
