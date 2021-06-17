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
        let input = ExamViewModel.Input()
        let output = viewModel.transform(input, disposeBag: disposeBag)
    }
}
