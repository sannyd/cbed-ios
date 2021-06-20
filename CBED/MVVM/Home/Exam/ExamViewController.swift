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
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var answerCollectionViewHeight: NSLayoutConstraint!
    
    // MARK: - Properties
    
    var viewModel: ExamViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: AnswerCollectionView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        bindViewModel()
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let input = ExamViewModel.Input(firstLoadTrigger: rxViewWillAppear,
                                        answerTapped: collectionView.rxItemSelected())
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .answers
            .asDriverOnErrorJustComplete()
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
        output
            .answers
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] answerSection in
//                self?.labelQuestion.text = question.content
                let cellWidth = UIScreen.main.bounds.width - 20 - 20 - 16 - 16 - 8 - 8 - 8 - 18
                let answerCount = answerSection.first?.items.count ?? 0
                let collectionViewHeight = answerSection.first?.items
                    
                    .compactMap { $0.answer.content?.height(withConstrainedWidth: cellWidth,
                                                                                      font: UIFont(name: Constants.Font.LatoRegular, size: 14)!) }
                    .map { $0 + 16 }
                    .map { $0 < 48 ? 48 : $0 }
                    .reduce(0, +)
                
                if let collectionViewHeight = collectionViewHeight {
                    self?.answerCollectionViewHeight.constant = collectionViewHeight + CGFloat((10 * answerCount)) + 20
                }
            }),
        output
            .currentQuestion
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] question in
                self?.labelQuestion.text = question.content
            }),
        output
            .navigationTitle
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] title in
                self?.labelTitle.text = title
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = AnswerCollectionView(lineSpacing: 14)
        collectionView.isScrollEnabled = false
        collectionView.contentInset = .init(top: 20,
                                            left: 0,
                                            bottom: 30,
                                            right: 0)
        collectionView.backgroundColor = .white
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
    }
}
