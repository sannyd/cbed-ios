//
//  LevelViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

final class NestedLevelViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var gradientViewHeight: NSLayoutConstraint!
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var buttonBack: UIButton!
    // MARK: - Properties
    
    var viewModel: NestedLevelViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<LevelM>, LevelCell>!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupCollectionView()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let viewWillAppear = rx
            .sentMessage(#selector(UIViewController.viewWillAppear))
            .mapToVoid()
        
        let input = NestedLevelViewModel.Input(firstLoadTrigger: Observable.merge(rxViewWillAppear),
                                               viewWillAppear: viewWillAppear,
                                               levelTapped: collectionView.rxModelSelected())
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .levels
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
         buttonBack
            .rxButtonTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }),
         output.title
            .drive(onNext: { [weak self] title in
                self?.labelTitle.text = title
            })
        ]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = CommonCollectionView<CommonCollectionViewSection<LevelM>, LevelCell>(lineSpacing: 30)
        collectionView.contentInset = .init(top: 20, left: 0, bottom: 30, right: 0)
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
    }
}
