//
//  CDCustomAlertView.swift
//  CantecCourier
//
//  Created by Jimmy Hoang on 10/27/20.
//

import UIKit
import RxSwift
import RxCocoa

class CustomTextView: UITextView {
    let maxHeight: CGFloat = 400
    override var contentSize: CGSize {
        didSet {
              let height = text.height(withConstrainedWidth: UIScreen.main.bounds.width - 20 - 20 - 22 - 22,
                        font: UIFont(name: Constants.Font.LatoRegular, size: 14 )!)
            if contentSize.height < height && contentSize.height > 92 {
                isScrollEnabled = true
            }
        }
    }
}

enum CustomAlertViewPublisher {
    case OKTapped(QuestionAlertType)
    case openUseLink(String)
    case cancelTapped
}
class CustomAlertView: BaseNibView {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var textViewDescription: CustomTextView!
    @IBOutlet weak var buttonYes: UIButton!
    @IBOutlet weak var buttonNo: UIButton!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var usefulLinkStackView: UIStackView!
    @IBOutlet weak var labelUsefulLink: UILabel!
    
    var type: QuestionAlertType = .correct
    var explainationLink: String?
    
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
                        rightButtonTitle: String?,
                        explainationLink: String?) {
        self.type = type
        labelTitle.text = title
        textViewDescription.text = description
        buttonYes.setTitle(leftButtonTitle, for: .normal)
        labelTitle.textColor = type.color
        buttonYes.backgroundColor = type.color
        
        if let explainationLink = explainationLink, !explainationLink.isEmpty {
            self.explainationLink = explainationLink
            usefulLinkStackView.isHidden = false
            let strings = explainationLink.split(separator: ",")
            labelUsefulLink.text = String(strings.first ?? "")
            
            switch type {
            case .correct:
                labelUsefulLink.textColor = Constants.PrimaryBlue
            case .wrong:
                labelUsefulLink.textColor = Constants.ColorE0293F
            }
        }
        
        if let rightButtonTitle = rightButtonTitle {
            buttonNo.setTitle(rightButtonTitle, for: .normal)
        } else {
            buttonNo.isHidden = true
        }
        
        setupUsefulLink()
    }
    
    @IBAction private func buttonYesInvoked(_ sender: UIButton) {
        publisher?.onNext(.OKTapped(type))
    }
    
    @IBAction private func buttonNoInvoked(_ sender: UIButton) {
        publisher?.onNext(.cancelTapped)
    }
    
    private func setupUsefulLink() {
        labelUsefulLink.rxGestureTapped
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else {
                    return
                }
                if let explainationLink = self.explainationLink {
                    let strings = explainationLink.split(separator: ",")
                    self.publisher?.onNext(.openUseLink(String(strings.last ?? "")))
                    self.publisher?.onNext(.OKTapped(self.type))
                }
            })
            .disposed(by: disposeBag)
    }
}
