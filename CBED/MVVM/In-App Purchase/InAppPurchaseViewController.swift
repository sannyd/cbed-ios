import UIKit
import RxSwift
import RxCocoa

final class InAppPurchaseViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var IAPBlockerView: UIView!
    @IBOutlet weak var buttonRestore: CustomBorderButton!
    @IBOutlet weak var labelLoadingPurchase: UILabel!
    
    // MARK: - Properties
    
    private var collectionView: CommonCollectionView<CommonCollectionViewSection<SubscriptionPlanM>, InAppPurchaseCell>!
    
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
                                                 inAppPurchaseItemTrigger: collectionView.rxModelSelected(),
                                                 buttonRestorePurchaseTrigger: buttonRestore.rxButtonTapped)
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .data
            .asDriverOnErrorJustComplete()
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
         output
            .purchaseSuccessInvoked
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            }),
         output
            .isShowingIAPBlockerView
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] isShowingIAPBlockerView, isRestore in
                if isRestore {
                    self?.labelLoadingPurchase.text = "Proceeding with restoring.\nPlease wait"
                } else {
                    self?.labelLoadingPurchase.text = "Proceeding with purchase.\nPlease wait"
                }
                
                if isShowingIAPBlockerView {
                    self?.IAPBlockerView.isHidden = false
                    self?.IAPBlockerView.isUserInteractionEnabled = true
                } else {
                    self?.IAPBlockerView.isHidden = true
                    self?.IAPBlockerView.isUserInteractionEnabled = false
                }
            }),
         output
            .restorePurchaseSuccess
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.IAPBlockerView.isHidden = true
                self?.IAPBlockerView.isUserInteractionEnabled = false
                NotificationCenter.default.post(.init(name: .PurchaseSuccessful))
//                self?.navigationController?.popViewController(animated: true)
            }),
         output
            .previouslyPurchasedInvoked
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.IAPBlockerView.isHidden = true
                self?.IAPBlockerView.isUserInteractionEnabled = false
                NotificationCenter.default.post(.init(name: .PurchaseSuccessful))
                self?.navigationController?.popViewController(animated: true)
            }),
         output
            .isLoading
            .asDriverOnErrorJustComplete()
            .drive(LoadingIndicatorView.rx.isAnimating),
         output
            .error
            .asDriverOnErrorJustComplete()
            .drive(errorBinding),
         backButton
            .rxButtonTapped
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] _ in
                self?.navigationController?.popViewController(animated: true)
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
    
    private func setupCollectionView() {
        collectionView = CommonCollectionView<CommonCollectionViewSection<SubscriptionPlanM>, InAppPurchaseCell>(lineSpacing: 20)
        collectionView.isScrollEnabled = false
        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(containerView.snp.edges) }
    }
}
