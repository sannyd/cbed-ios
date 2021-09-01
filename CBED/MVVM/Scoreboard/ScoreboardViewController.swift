//
//  ScoreboardViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit
import RxSwift
import RxCocoa

final class ScoreboardViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var labelUserName: UILabel!
    @IBOutlet weak var labelUserPosition: UILabel!
    @IBOutlet weak var labelProBarFeb: UILabel!
    @IBOutlet weak var labelProBarJuly: UILabel!
    @IBOutlet weak var labelBabyBarJun: UILabel!
    @IBOutlet weak var labelBabyBarOct: UILabel!
    @IBOutlet weak var collectionContainerView: UIView!
    @IBOutlet weak var highlightView: CustomBorderView!
    @IBOutlet weak var highlightViewLeading: NSLayoutConstraint!
    
    // MARK: - Properties
    
    var viewModel: ScoreboardViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<ScoreM>, ScoreCell>!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        
        if !IsEnableLogin {
            labelUserName.text = "Newcomer"
            labelUserPosition.isHidden = true
            profileImageView.image = #imageLiteral(resourceName: "img_user_placeholder")
        }
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let proBarFebTrigger = labelProBarFeb
            .rxGestureTapped
            .map { _ in InAppPurchaseMonth.ProBarFeb }
        
        let proBarJulTrigger = labelProBarJuly
            .rxGestureTapped
            .map { _ in InAppPurchaseMonth.ProBarJul }
        
        let babyBarJuneTrigger = labelBabyBarJun
            .rxGestureTapped
            .map { _ in InAppPurchaseMonth.BabyBarJun }
        
        let babyBarOctTrigger = labelBabyBarOct
            .rxGestureTapped
            .map { _ in InAppPurchaseMonth.BabyBarOct }
        
        let viewWillAppear = rx
            .sentMessage(#selector(UIViewController.viewWillAppear))
            .mapToVoid()
        
        let pullToRefreshTrigger = collectionView
            .refreshControl!
            .rx
            .controlEvent(.valueChanged)
            .asObservable()
        
        let input = ScoreboardViewModel.Input(firstLoadTrigger: Observable.merge(pullToRefreshTrigger,
                                                                                 rxViewWillAppear),
                                              viewWillAppear: viewWillAppear,
                                              filterTrigger: Observable.merge(proBarFebTrigger,
                                                                              proBarJulTrigger,
                                                                              babyBarJuneTrigger,
                                                                              babyBarOctTrigger))
        
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .data
            .asDriverOnErrorJustComplete()
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
         output
            .filterInvoked
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [unowned self] filterType in
                let offset: CGFloat = 20
                
                labelProBarFeb.textColor = .black
                labelProBarJuly.textColor = .black
                labelBabyBarJun.textColor = .black
                labelBabyBarOct.textColor = .black
                
                switch filterType {
                case .ProBarFeb:
                    labelProBarFeb.textColor = .white
                    highlightViewLeading.constant = 8
                case .ProBarJul:
                    labelProBarJuly.textColor = .white
                    highlightViewLeading.constant = highlightView.bounds.width + offset + 8
                case .BabyBarJun:
                    labelBabyBarJun.textColor = .white
                    highlightViewLeading.constant = highlightView.bounds.width * 2 + offset * 2 + 8
                case .BabyBarOct:
                    labelBabyBarOct.textColor = .white
                    highlightViewLeading.constant = highlightView.bounds.width * 3 + offset * 3 + 8
                }
                UIView.animate(withDuration: 0.35) {
                    self.view.layoutIfNeeded()
                }
            }),
         output
            .userProfile
            .unwrap()
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] profile in
                self?.labelUserName.text = IsEnableLogin ? profile.email : "Newcomer"
                self?.labelUserPosition.text = IsEnableLogin ? "👑 \(profile.lastSectionName ?? "N/A")" : ""
                if IsEnableLogin {
                    self?.profileImageView.loadImage(with: profile.avatar,
                                                     placeholder: #imageLiteral(resourceName: "img_user_placeholder"))
                } else {
                    self?.profileImageView.image = #imageLiteral(resourceName: "img_user_placeholder")
                }
            }),
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
            .drive(errorBinding)]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = CommonCollectionView<CommonCollectionViewSection<ScoreM>, ScoreCell>(lineSpacing: 14)
        collectionView.contentInset = .init(top: 20,
                                            left: 0,
                                            bottom: 30,
                                            right: 0)
        collectionContainerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(collectionContainerView.snp.edges) }
    }
}
