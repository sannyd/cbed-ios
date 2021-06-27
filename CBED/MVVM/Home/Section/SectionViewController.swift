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
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<SectionM>, SectionCell>!
    
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
                                            sectionTapped: collectionView.rxModelSelected())
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .navigationTitle
            .drive(onNext: { [weak self] title in
                self?.labelNavigationTitle.text = title
            }),
        output
            .sections
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
        output
           .isLoading
           .drive(onNext: { [weak self] isLoading in
               if isLoading {
                   self?.collectionView.refreshControl?.beginRefreshing()
               } else {
                   self?.collectionView.refreshControl?.endRefreshing()
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
        collectionView = CommonCollectionView<CommonCollectionViewSection<SectionM>, SectionCell>(lineSpacing: 14)
        collectionView.contentInset = .init(top: 20,
                                            left: 0,
                                            bottom: 30,
                                            right: 0)
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
    }
}
