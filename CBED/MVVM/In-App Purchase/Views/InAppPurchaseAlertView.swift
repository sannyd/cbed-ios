//
//  InAppPurchaseAlertView.swift
//  CBED
//
//  Created by Jimmy Hoang on 18/07/2021.
//

import UIKit
import RxSwift
import RxCocoa
import SwiftEntryKit

enum InAppPurchaseAlertViewPublisher {
    case didTapProceed(month: InAppPurchaseMonth)
}

class InAppPurchaseAlertView: BaseNibView {
    @IBOutlet weak var buttonProceed: UIButton!
    @IBOutlet weak var leftView: CustomBorderView!
    @IBOutlet weak var rightView: CustomBorderView!
    @IBOutlet weak var labelLeft: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    var viewModel: InAppPurchaseAlertViewModel!
    weak var publisher: PublishSubject<InAppPurchaseAlertViewPublisher>!
    
    let disposeBag = DisposeBag()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadContentViewWithNib(nibName: InAppPurchaseAlertView.nibName())
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        loadContentViewWithNib(nibName: InAppPurchaseAlertView.nibName())
    }
    
    convenience init(viewModel: InAppPurchaseAlertViewModel) {
        self.init()
        self.viewModel = viewModel
        bindViewModel()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        buttonProceed.roundCorners([.layerMinXMaxYCorner,
                                .layerMaxXMaxYCorner], radius: 10)
    }
    
    private func bindViewModel() {
        let leftViewTapped = leftView.rxGestureTapped.map { _ in 0 }
        let rightViewTapped = rightView.rxGestureTapped.map { _ in 1 }
        
        let input = InAppPurchaseAlertViewModel.Input(selectedMonth: Observable.merge(leftViewTapped,
                                                                                      rightViewTapped),
                                                      buttonProceedTrigger: buttonProceed.rxButtonTapped)
        
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .leftData
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] data in
                self?.labelLeft.text = data.type.monthString
                self?.leftView.backgroundColor = data.isSelected ? Constants.PrimaryBlue :  Constants.primaryTextfieldColor
            }),
         output
            .rightData
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] data in
                self?.rightLabel.text = data.type.monthString
                self?.rightView.backgroundColor = data.isSelected ? Constants.PrimaryBlue : Constants.primaryTextfieldColor
            }),
         output
            .isButtonProceedValid
            .asDriverOnErrorJustComplete()
            .drive(buttonProceed.rx.isEnabled),
         output
            .buttonProceedInvoked
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] (month) -> () in
                self?.publisher.onNext(.didTapProceed(month: month))
                SwiftEntryKit.dismiss()
            })
        ]
        .forEach { $0.disposed(by: disposeBag) }
    }
}

struct InAppPurchaseMonthM {
    var isSelected: Bool
    var type: InAppPurchaseMonth
}

// MARK: Input + Output
extension InAppPurchaseAlertViewModel {
    struct Input {
        let selectedMonth: Observable<Int>
        let buttonProceedTrigger: Observable<Void>
    }
    
    struct Output {
        let leftData: Observable<InAppPurchaseMonthM>
        let rightData: Observable<InAppPurchaseMonthM>
        let isButtonProceedValid: Observable<Bool>
        let buttonProceedInvoked: Observable<InAppPurchaseMonth>
    }
}

struct InAppPurchaseAlertViewModel: ViewModel {
    let leftData: BehaviorRelay<InAppPurchaseMonthM>
    let rightData: BehaviorRelay<InAppPurchaseMonthM>
    
    func transform(_ input: Input, disposeBag: DisposeBag) -> Output {
        input
            .selectedMonth
            .subscribe(onNext: { index in
                if index == 0 {
                    var tempLeft = leftData.value
                    tempLeft.isSelected = true
                    leftData.accept(tempLeft)
                    
                    var tempRight = rightData.value
                    tempRight.isSelected = false
                    rightData.accept(tempRight)
                } else {
                    var tempLeft = leftData.value
                    tempLeft.isSelected = false
                    leftData.accept(tempLeft)
                    
                    var tempRight = rightData.value
                    tempRight.isSelected = true
                    rightData.accept(tempRight)
                }
            })
            .disposed(by: disposeBag)
        
        let isButtonProceedValid = Observable.combineLatest(leftData.asObservable(),
                                                            rightData.asObservable())
            .map { leftData, rightData in
                leftData.isSelected || rightData.isSelected
            }
        
        let buttonProceedInvoked = input
            .buttonProceedTrigger
            .withLatestFrom(Observable.combineLatest(leftData.asObservable(),
                                                     rightData.asObservable()))
            .map { leftData, rightData -> InAppPurchaseMonth? in
                if leftData.isSelected {
                    return leftData.type
                }
                
                if rightData.isSelected {
                    return leftData.type
                }
                
                return nil
            }
            .unwrap()
        
        return Output(leftData: leftData.asObservable(),
                      rightData: rightData.asObservable(),
                      isButtonProceedValid: isButtonProceedValid,
                      buttonProceedInvoked: buttonProceedInvoked)
    }
}
