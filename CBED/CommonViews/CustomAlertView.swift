//
//  CDCustomAlertView.swift
//  CantecCourier
//
//  Created by Jimmy Hoang on 10/27/20.
//

import UIKit
import RxSwift
import RxCocoa

class SelfSizingTextView: UITextView {
    var runOnce = false
    
    private var preferredMaxLayoutWidth: CGFloat? {
        didSet {
            guard preferredMaxLayoutWidth != oldValue else { return }
            invalidateIntrinsicContentSize()
        }
    }
    
    override var text: String! {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override var intrinsicContentSize: CGSize {
        guard let width = preferredMaxLayoutWidth else {
            return super.intrinsicContentSize
        }
        
        let height = textHeightForWidth(width)
        return CGSize(width: width, height: height > 200 ? 200 : height)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        preferredMaxLayoutWidth = bounds.width
        
        guard !runOnce else {
            return
        }
        runOnce = true
        contentOffset = .zero
    }
}

private extension UIEdgeInsets {
    var horizontal: CGFloat { return left + right }
    var vertical: CGFloat { return top + bottom }
}

private extension UITextView {
    func textHeightForWidth(_ width: CGFloat) -> CGFloat {
        let storage = NSTextStorage(attributedString: attributedText)
        let width = bounds.width - textContainerInset.horizontal
        let containerSize = CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        let container = NSTextContainer(size: containerSize)
        let manager = NSLayoutManager()
        manager.addTextContainer(container)
        storage.addLayoutManager(manager)
        container.lineFragmentPadding = textContainer.lineFragmentPadding
        container.lineBreakMode = textContainer.lineBreakMode
        _ = manager.glyphRange(for: container)
        let usedHeight = manager.usedRect(for: container).height
        return ceil(usedHeight + textContainerInset.vertical)
    }
}

enum CustomAlertViewPublisher {
    case OKTapped(QuestionAlertType)
    case openUseLink(String)
    case cancelTapped
}
class CustomAlertView: BaseNibView {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var textViewDescription: SelfSizingTextView!
    @IBOutlet weak var buttonYes: UIButton!
    @IBOutlet weak var buttonNo: UIButton!
    @IBOutlet weak var buttonStackView: UIStackView!
    @IBOutlet weak var usefulLinkStackView: UIStackView!
    @IBOutlet weak var labelUsefulLink: UILabel!
    
    var type: QuestionAlertType = .correct
    var explainationLink: String?
    
    var publisher: PublishSubject<CustomAlertViewPublisher>?
    
    var disposeBag = DisposeBag()
    
    var onOKTapped: (() -> Void)?
    
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
        textViewDescription.scaledFont(style: .body)
        labelTitle.text = title
        textViewDescription.isScrollEnabled = true
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
        textViewDescription.flashScrollIndicators()
    }
    
    @IBAction private func buttonYesInvoked(_ sender: UIButton) {
        onOKTapped?()
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
