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
    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var labelTime: UILabel!
    
    // MARK: - Properties
    
    var viewModel: ExamViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: AnswerCollectionView<CommonCollectionViewSection<SelectableAnswer>, AnswerCell>!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.contentInset = .init(top: 16, left: 0, bottom: 0, right: 0)
        setupFont()
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
            }),
        output
            .numberOfQuestions
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] title in
                self?.labelSubtitle.text = title
            }),
        output
            .timerText
            .asDriver(onErrorJustReturn: "N/A")
            .drive(onNext: { [weak self] text in
                self?.labelTime.text = text
            }),
        buttonBack
            .rxButtonTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }),
        output
            .scrollToTopInvoked
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.scrollView.setContentOffset(.zero, animated: true)
            }),
        output
            .isLoading
            .asDriverOnErrorJustComplete()
            .drive(LoadingIndicatorView.rx.isAnimating),
        output
            .error
            .asDriverOnErrorJustComplete()
            .drive(errorBinding)]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = AnswerCollectionView(lineSpacing: 14)
        collectionView.isScrollEnabled = false
        collectionView.contentInset = .init(top: 0,
                                            left: 0,
                                            bottom: 0,
                                            right: 0)
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
    }
    
    private func setupFont() {
        labelQuestion.scaledFont(style: .body)
    }
}
