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
        let input = SectionsViewModel.Input(firstLoadTrigger: rxViewWillAppear)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .navigationTitle
            .drive(onNext: { [weak self] title in
                self?.labelNavigationTitle.text = title
            }),
        output
            .sections
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource))]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = CommonCollectionView<CommonCollectionViewSection<SectionM>, SectionCell>(cellHeight: 162,
                                                                                                  cellWidth: UIScreen.main.bounds.width - 30 - 30,
                                                                                                  lineSpacing: 14)
        collectionView.contentInset = .init(top: 20,
                                            left: 0,
                                            bottom: 30,
                                            right: 0)
        collectionView.backgroundColor = .white
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
    }
}
