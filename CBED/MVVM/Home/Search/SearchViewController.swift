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
    @IBOutlet weak var gradientView: GradientBackgroundView!
    
    // MARK: - Properties
    
    var viewModel: SearchViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<SearchResultM>, SectionCell>!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextfield.becomeFirstResponder()
        searchTextfield.autocorrectionType = .no
        searchTextfield.spellCheckingType = .no
        setupCollectionView()
        setupGradientView()
        bindViewModel()
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let rawSearchText = searchTextfield
            .rx
            .text
            .orEmpty
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .distinctUntilChanged { lhs, rhs in
                lhs.caseInsensitiveCompare(rhs) == .orderedSame
            }
        let searchText = viewModel.level.id == 8
            ? rawSearchText
            : rawSearchText.filter { !$0.isEmpty }
        let input = SearchViewModel.Input(searchText: searchText,
                                          firstLoadTrigger: rxViewWillAppear,
                                          loadMoreTrigger: collectionView.rx_reachedBottom,
                                          sectionTapped: collectionView.rxModelSelected())
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .sections
            .asDriver(onErrorJustReturn: [])
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
//         collectionView.rx.didScroll
//            .mapToVoid()
//            .asDriverOnErrorJustComplete()
//            .skip(1)
//            .drive(onNext: { [weak self] _ in
//                self?.searchTextfield.resignFirstResponder()
//            }),
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
    
    private func setupGradientView() {
        let layer = gradientView.layer as! CAGradientLayer
        layer.startPoint = .init(x: 0.5, y: 0)
        layer.endPoint = .init(x: 0.5, y: 1)
        layer.colors = [#colorLiteral(red: 0.1607843137, green: 0.3568627451, blue: 0.8784313725, alpha: 1).cgColor, #colorLiteral(red: 0.5058823529, green: 0.2078431373, blue: 0.8862745098, alpha: 1).cgColor]
        
        gradientView.roundCorners([.layerMinXMaxYCorner,
                                   .layerMaxXMaxYCorner], radius: 50)
    }
}
