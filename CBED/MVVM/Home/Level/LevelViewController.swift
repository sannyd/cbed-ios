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
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchTitleLabel: UILabel!
    @IBOutlet weak var unlockView: UIView!
    
    // MARK: - Properties
    
    var viewModel: LevelViewModel!
    var disposeBag = DisposeBag()
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<LevelM>, LevelCell>!
    private var hasShownMPRESubscriberWarning = false
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchView.isUserInteractionEnabled = true

        setupCollectionView()
        setupGradientView()
        bindViewModel()
        
        searchView.setCornerRadius(radius: 20)
        updateSearchTitle()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        
        searchView.isHidden = !IsEnableLogin
        updateSearchTitle()
        
        if !IsEnableLogin {
            if CurrentMembershipType == nil {
                unlockView.isHidden = false
            } else {
                unlockView.isHidden = true
            }
        } else {
            if let userProfile = Storage.profileInfo {
                if userProfile.memberPlan == .free {
                    unlockView.isHidden = false
                } else {
                    unlockView.isHidden = true
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        presentMPRESubscriberWarningIfNeeded()
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
        
        let purchaseSuccessfulTrigger = NotificationCenter.default.rx
            .notification(.PurchaseSuccessful)
            .mapToVoid()
        
        let input = LevelViewModel.Input(firstLoadTrigger: Observable.merge(pullToRefreshTrigger,
                                                                            purchaseSuccessfulTrigger,
                                                                            rxViewWillAppear),
                                         viewWillAppear: viewWillAppear,
                                         levelTapped: collectionView.rxModelSelected(),
                                         searchViewTapped: searchView.rxGestureTapped.map { LevelM(id: Storage.examLocation.searchLevelID, name: nil) },
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
                guard let profile = profile, IsEnableLogin else {
                    return
                }
                
                switch profile.memberPlan {
                case .free:
                    self?.unlockView.isHidden = false
                default:
                    self?.unlockView.isHidden = true
                }
                self?.presentMPRESubscriberWarningIfNeeded()
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

    private func updateSearchTitle() {
        searchTitleLabel.text = Storage.examLocation.homeSearchTitle
    }

    private func presentMPRESubscriberWarningIfNeeded() {
        guard Storage.examLocation == .mpre,
              isCurrentUserSubscriber,
              !hasShownMPRESubscriberWarning,
              presentedViewController == nil else {
            return
        }

        hasShownMPRESubscriberWarning = true
        let alert = UIAlertController(title: "MPRE Materials",
                                      message: "If you are a subscriber and are only seeing MPRE materials, please go to Settings to update your jurisdiction to your correct exam location.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private var isCurrentUserSubscriber: Bool {
        if IsEnableLogin {
            guard let memberPlan = Storage.profileInfo?.memberPlan else {
                return false
            }
            return memberPlan != .free
        }

        return CurrentMembershipType != nil
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
