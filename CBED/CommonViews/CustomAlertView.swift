//
//  CDCustomAlertView.swift
//  CantecCourier
//
//  Created by Jimmy Hoang on 10/27/20.
//

import UIKit
import RxSwift
import RxCocoa

enum CustomAlertViewPublisher {
    case OKTapped(QuestionAlertType)
    case cancelTapped
}
class CustomAlertView: BaseNibView {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var buttonYes: UIButton!
    @IBOutlet weak var buttonNo: UIButton!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var usefulLinkStackView: UIStackView!
    @IBOutlet weak var labelUsefulLink: UILabel!
    
    
    var type: QuestionAlertType = .correct
    
    var publisher: PublishSubject<CustomAlertViewPublisher>?
    
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContentViewWithNib(nibName: CustomAlertView.nibName())
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadContentViewWithNib(nibName: CustomAlertView.nibName())
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        buttonYes.roundCorners([.layerMinXMaxYCorner,
                                .layerMaxXMaxYCorner], radius: 10)
    }

    func setupAlertView(title: String?,
                        description: String?,
                        type: QuestionAlertType,
                        leftButtonTitle: String = "OK",
                        rightButtonTitle: String?) {
        self.type = type
        labelTitle.text = title
        labelDescription.text = description
        buttonYes.setTitle(leftButtonTitle, for: .normal)
        labelTitle.textColor = type.color
        buttonYes.backgroundColor = type.color
        
        if let rightButtonTitle = rightButtonTitle {
            buttonNo.setTitle(rightButtonTitle, for: .normal)
        } else {
            buttonNo.isHidden = true
//            separatorLine.isHidden = true
        }
    }
    
    @IBAction private func buttonYesInvoked(_ sender: UIButton) {
        publisher?.onNext(.OKTapped(type))
    }
    
    @IBAction private func buttonNoInvoked(_ sender: UIButton) {
        publisher?.onNext(.cancelTapped)
    }
}
