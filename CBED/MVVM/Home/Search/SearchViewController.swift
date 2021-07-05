//
//  SearchViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 7/2/21.
//

import UIKit
import RxSwift
import RxCocoa

final class SearchViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var searchTextfield: UITextField!
    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var containerView: UIView!
    // MARK: - Properties
    
    var viewModel: SearchViewModel!
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
        let searchText = searchTextfield
            .rx
            .text
            .orEmpty
            .debounce(.milliseconds(300), scheduler: MainScheduler.instance)
            .distinctUntilChanged()
        let input = SearchViewModel.Input(searchText: searchText,
                                          firstLoadTrigger: rxViewWillAppear,
                                          loadMoreTrigger: collectionView.rx_reachedBottom,
                                          sectionTapped: collectionView.rxModelSelected())
        let output = viewModel.transform(input, disposeBag: disposeBag)
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
