//
//  SectionDetailViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 16/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

final class SectionDetailViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var sectionImageView: UIImageView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var labelSectionName: UILabel!
    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var buttonStart: CustomBorderButton!
    
    // MARK: - Properties
    
    var viewModel: SectionDetailViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<UsefulLink>, UsefulLinkCell>!
    
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
        let input = SectionDetailViewModel.Input(firstLoadTrigger: rxViewWillAppear,
                                                 usefulLinkTapped: collectionView.rxModelSelected(),
                                                 buttonStartTrigger: buttonStart.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .usefulLinks
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
         output
            .sectionInfo
            .drive(onNext: { [weak self] sectionInfo in
                self?.labelSectionName.text = sectionInfo.levelTitle
            }),
         output
            .isLoading
            .drive(LoadingIndicatorView.rx.isAnimating),
         output
            .error
            .drive(errorBinding),
         buttonBack
            .rxButtonTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = CommonCollectionView<CommonCollectionViewSection<UsefulLink>, UsefulLinkCell>(lineSpacing: 14)
        collectionView.contentInset = .init(top: 20,
                                            left: 0,
                                            bottom: 30,
                                            right: 0)
        collectionView.backgroundColor = .white
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
    }
}
