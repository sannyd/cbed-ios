//
//  ExamViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 17/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

final class ExamViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelSubtitle: UILabel!
    @IBOutlet weak var labelQuestion: UILabel!
    
    // MARK: - Properties
    
    var viewModel: ExamViewModel!
    var disposeBag = DisposeBag()
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let input = ExamViewModel.Input(firstLoadTrigger: rxViewWillAppear,
                                        answerTapped: .empty(),
                                        correctAlertTapped: .empty(),
                                        wrongAlertTapped: .empty())
        let output = viewModel.transform(input, disposeBag: disposeBag)
    }
}
