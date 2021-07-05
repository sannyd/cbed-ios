//
//  SectionViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 15/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

final class SectionsViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var labelNavigationTitle: UILabel!
    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var containerView: UIView!
    // MARK: - Properties
    
    var viewModel: SectionsViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<SearchResultM>, SectionCell>!
    
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
        let pullToRefreshTrigger = collectionView
            .refreshControl!
            .rx
            .controlEvent(.valueChanged)
            .asObservable()
        
        let input = SectionsViewModel.Input(firstLoadTrigger: Observable.merge(pullToRefreshTrigger,
                                                                               rxViewWillAppear),
                                            loadMoreTrigger: collectionView.rx_reachedBottom,
                                            sectionTapped: collectionView.rxModelSelected())
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .navigationTitle
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] title in
                self?.labelNavigationTitle.text = title
            }),
        output
            .sections
            .asDriverOnErrorJustComplete()
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
        output
           .isLoading
            .asDriverOnErrorJustComplete()
           .drive(onNext: { [weak self] isLoading in
               if isLoading {
                   self?.collectionView.refreshControl?.beginRefreshing()
               } else {
                   self?.collectionView.refreshControl?.endRefreshing()
               }
           }),
        output
            .error
            .asDriverOnErrorJustComplete()
            .drive(errorBinding),
        output
            .isLoadMore
            .asDriver(onErrorJustReturn: false)
            .drive(collectionView.rx.loadingMore),
        output
            .isLastPagination
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] isLastPagination in
                if isLastPagination {
                    self?.collectionView.setLoadMoreEnable(false)
                } else {
                    self?.collectionView.setLoadMoreEnable(true)
                }
            }),
        buttonBack
           .rxButtonTapped
           .asDriverOnErrorJustComplete()
           .drive(onNext: { [weak self] _ in
               self?.navigationController?.popViewController(animated: true)
           })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = CommonCollectionView<CommonCollectionViewSection<SearchResultM>, SectionCell>(lineSpacing: 14)
        collectionView.contentInset = .init(top: 20,
                                            left: 0,
                                            bottom: 100,
                                            right: 0)
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
        collectionView.addLoadMore {}
    }
}
