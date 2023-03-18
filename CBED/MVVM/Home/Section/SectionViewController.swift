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
    @IBOutlet weak var buttonScrollToLastPage: CustomBorderButton!
    // MARK: - Properties
    
    var viewModel: SectionsViewModel!
    var disposeBag = DisposeBag()
    private var isScrollToLast = true {
        didSet {
            buttonScrollToLastPage.setImage(isScrollToLast ? UIImage(systemName: "chevron.down") : UIImage(systemName: "chevron.up"), for: .normal)
        }
    }
    
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
        buttonScrollToLastPage.addTarget(self, action: #selector(scrollToLastPage), for: .touchUpInside)
        
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
           .isReloading
            .asDriverOnErrorJustComplete()
           .drive(onNext: { [weak self] isLoading in
               if isLoading {
                   self?.collectionView.refreshControl?.beginRefreshing()
               } else {
                   self?.collectionView.refreshControl?.endRefreshing()
               }
           }),
        output
            .isLoading
            .asDriverOnErrorJustComplete()
            .drive(LoadingIndicatorView.rx.isAnimating),
        output
            .isLoadMore
            .asDriver(onErrorJustReturn: false)
            .drive(collectionView.rx.loadingMore),
        output
            .error
            .asDriverOnErrorJustComplete()
            .drive(errorBinding),
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
    
    @objc private func scrollToLastPage() {
        if isScrollToLast {
            DispatchQueue.main.async { self.collectionView.scrollToBottom(animated: true) }
        } else {
            DispatchQueue.main.async { self.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0),
                                                                        at: .top, animated: true) }
        }
        
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
        collectionView.onScroll = { [weak self] scrollView in
            let content = scrollView.contentOffset.y / scrollView.contentSize.height * 100
            
            if content >= 95 {
                self?.isScrollToLast = false
            } else {
                self?.isScrollToLast = true
            }
        }
    }
}

extension UICollectionView {

    // MARK: - UICollectionView scrolling/datasource
    /// Last Section of the CollectionView
    var lastSection: Int {
        return numberOfSections - 1
    }

    /// IndexPath of the last item in last section.
    var lastIndexPath: IndexPath? {
        guard lastSection >= 0 else {
            return nil
        }

        let lastItem = numberOfItems(inSection: lastSection) - 1
        guard lastItem >= 0 else {
            return nil
        }

        return IndexPath(item: lastItem, section: lastSection)
    }

    /// Islands: Scroll to bottom of the CollectionView
    /// by scrolling to the last item in CollectionView
    func scrollToBottom(animated: Bool) {
        guard let lastIndexPath = lastIndexPath else {
            return
        }
        scrollToItem(at: lastIndexPath, at: .bottom, animated: animated)
    }
}
