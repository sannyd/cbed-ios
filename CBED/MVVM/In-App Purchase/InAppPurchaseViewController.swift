//
//  InAppPurchaseViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 07/07/2021.
//

import UIKit
import RxSwift
import RxCocoa

final class InAppPurchaseViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var backButton: UIButton!
    
    // MARK: - Properties
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<InAppPurchaseType>, InAppPurchaseCell>!
    
    var viewModel: InAppPurchaseViewModel!
    var disposeBag = DisposeBag()
    
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
        let input = InAppPurchaseViewModel.Input(firstLoadTrigger: rxViewWillAppear,
                                                 inAppPurchaseItemTrigger: collectionView.rxModelSelected())
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .data
            .asDriverOnErrorJustComplete()
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
         backButton
            .rxButtonTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = CommonCollectionView<CommonCollectionViewSection<InAppPurchaseType>, InAppPurchaseCell>(lineSpacing: 20)
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
        collectionView.addLoadMore {}
    }
}
