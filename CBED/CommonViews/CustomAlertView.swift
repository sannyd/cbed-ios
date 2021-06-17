//
//  CDCustomAlertView.swift
//  CantecCourier
//
//  Created by Jimmy Hoang on 10/27/20.
//

import UIKit
import RxSwift
import RxCocoa

protocol CDCustomAlertViewDelegate: class {
    func didTapYes()
    func didTapNo()
}

class CustomAlertView: BaseNibView {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    @IBOutlet weak var buttonYes: UIButton!
    @IBOutlet weak var buttonNo: UIButton!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var separatorLine: UIView!
    
    weak var delegate: CDCustomAlertViewDelegate?
    
    var didTapOK = PublishRelay<Void>()
    var didTapNo = PublishRelay<Void>()
    
    var disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContentViewWithNib(nibName: CDCustomAlertView.nibName())
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadContentViewWithNib(nibName: CDCustomAlertView.nibName())
    }

    func setupAlertView(title: String?,
                        description: String?,
                        leftButtonTitle: String = "YES",
                        rightButtonTitle: String?) {
        labelTitle.text = title
        labelDescription.text = description
        buttonYes.setTitle(leftButtonTitle, for: .normal)
        if let rightButtonTitle = rightButtonTitle {
            buttonNo.setTitle(rightButtonTitle, for: .normal)
        } else {
            buttonNo.isHidden = true
            separatorLine.isHidden = true
        }
    }
    
    @IBAction private func buttonYesInvoked(_ sender: UIButton) {
        didTapOK.accept(())
        delegate?.didTapYes()
    }
    
    @IBAction private func buttonNoInvoked(_ sender: UIButton) {
        didTapNo.accept(())
        delegate?.didTapNo()
    }
}
