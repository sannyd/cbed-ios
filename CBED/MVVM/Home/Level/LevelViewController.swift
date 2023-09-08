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
import SwiftyMenu

struct SearchSection {
    let level: LevelM
}

extension SearchSection: SwiftyMenuDisplayable {
    public var displayableValue: String {
        return self.level.name ?? ""
    }

    public var retrievableValue: Any {
        return self.level
    }
}

final class LevelViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var gradientView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var gradientViewHeight: NSLayoutConstraint!
    @IBOutlet weak var searchView: SwiftyMenu!
    @IBOutlet weak var unlockView: UIView!
    private var codeMenuAttributes = SwiftyMenuAttributes()
    let selectSearchSection = PublishSubject<LevelM>()
    
    // MARK: - Properties
    
    var viewModel: LevelViewModel!
    var disposeBag = DisposeBag()
    private let dropDownOptionsDataSource = [
        SearchSection(level: LevelM(id: 9, name: "CA Essay Drills & Videos", order: 7)),
        SearchSection(level: LevelM(id: 7, name: "MEE Drills & Videos", order: 9)),
    ]
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<LevelM>, LevelCell>!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchView.isUserInteractionEnabled = true
        searchView.items = dropDownOptionsDataSource
        codeMenuAttributes.multiSelect = .disabled
        codeMenuAttributes.hideOptionsWhenSelect = .enabled
        codeMenuAttributes.rowStyle = .value(height: 60, backgroundColor: .white, selectedColor: .white)
        codeMenuAttributes.roundCorners = .all(radius: 8)
        codeMenuAttributes.border = .value(color: .gray, width: 0.5)
        codeMenuAttributes.placeHolderStyle = .value(text: "Select a level to search", textColor: .black)
        codeMenuAttributes.separatorStyle = .value(color: .black, isBlured: false, style: .singleLine)
        searchView.configure(with: codeMenuAttributes)
        
        searchView.didSelectItem = { [weak self] menu, item, index in
            guard let self else { return }
            print("Selected \(item) at index: \(index)")
            if let level = item.retrievableValue as? LevelM {
                self.selectSearchSection.onNext(level)
                self.searchView.selectedIndex = nil
            }
        }
        searchView.willExpand = { [weak self] in
            self?.collectionView.isUserInteractionEnabled = false
        }
        searchView.willCollapse = { [weak self] in
            self?.collectionView.isUserInteractionEnabled = true
        }

        setupCollectionView()
        setupGradientView()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        
        searchView.isHidden = !IsEnableLogin
        
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
                                         searchViewTapped: selectSearchSection.asObservable(),
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
