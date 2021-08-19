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

final class LevelViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var gradientViewHeight: NSLayoutConstraint!
    @IBOutlet weak var searchView: CustomBorderView!
    @IBOutlet weak var unlockView: UIView!
    
    // MARK: - Properties
    
    var viewModel: LevelViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<LevelM>, LevelCell>!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        setupGradientView()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        //        gradientViewHeight.constant += self.view.safeAreaInsets.top
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
        let pullToRefreshTrigger = collectionView
            .refreshControl!
            .rx
            .controlEvent(.valueChanged)
            .asObservable()
        
        let viewWillAppear = rx
            .sentMessage(#selector(UIViewController.viewWillAppear))
            .mapToVoid()
        
        let input = LevelViewModel.Input(firstLoadTrigger: Observable.merge(pullToRefreshTrigger,
                                                                            rxViewWillAppear),
                                         viewWillAppear: viewWillAppear,
                                         levelTapped: collectionView.rxModelSelected(),
                                         searchViewTapped: searchView.rxGestureTapped,
                                         unlockViewTapped: unlockView.rxGestureTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .levels
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
         output
            .isReloading
            .drive(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.collectionView.refreshControl?.beginRefreshing()
                } else {
                    self?.collectionView.refreshControl?.endRefreshing()
                }
            }),
         output
            .isLoading
            .drive(LoadingIndicatorView.rx.isAnimating),
        output
            .userProfile
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] profile in
                guard let profile = profile else {
                    return
                }
                
                switch profile.memberPlan {
                case .free:
                    self?.unlockView.isHidden = false
                default:
                    self?.unlockView.isHidden = true
                }
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = CommonCollectionView<CommonCollectionViewSection<LevelM>, LevelCell>(lineSpacing: 30)
        collectionView.contentInset = .init(top: 20, left: 0, bottom: 30, right: 0)
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
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

class GradientBackgroundView: UIView {
    // Enables more convenient access to layer
    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }
    
    override open class var layerClass: AnyClass {
        return CAGradientLayer.classForCoder()
    }
}
