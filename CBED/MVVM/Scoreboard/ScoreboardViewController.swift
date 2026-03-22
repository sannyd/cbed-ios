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
    
    @IBOutlet weak var collectionContainerView: UIView!
    @IBOutlet weak var highlightView: CustomBorderView!
    @IBOutlet weak var highlightViewLeading: NSLayoutConstraint!
    @IBOutlet weak var labelBabyBarSection: UILabel!
    @IBOutlet weak var labelZoomEmailSection: UILabel!
    
    
    @IBOutlet weak var zoomEmailContainerView: CustomBorderView!
    @IBOutlet weak var zoomEmailHighlightView: CustomBorderView!
    @IBOutlet weak var zoomEmailHighlightViewLeading: NSLayoutConstraint!
    @IBOutlet weak var labelEssays: UILabel!
    @IBOutlet weak var labelMPT: UILabel!
    @IBOutlet weak var labelMBE: UILabel!
    
    @IBOutlet weak var babyBarContainerView: CustomBorderView!
    @IBOutlet weak var babyBarHighlightView: CustomBorderView!
    @IBOutlet weak var babyBarHighlightViewLeading: NSLayoutConstraint!
    @IBOutlet weak var labelBabyBarJun: UILabel!
    @IBOutlet weak var labelBabyBarOct: UILabel!
    
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
            .map { _ in ScoreboardSection.barExamFeb }
        
        let proBarJulTrigger = labelProBarJuly
            .rxGestureTapped
            .map { _ in ScoreboardSection.barExamJuly }
        
        let babyBarSectionTrigger = labelBabyBarSection
            .rxGestureTapped
            .map { _ in ScoreboardSection.babyBar(.june) }
        
        let babyBarJuneTrigger = labelBabyBarJun
            .rxGestureTapped
            .map { _ in ScoreboardSection.babyBar(.june) }
        
        let babyBarOctTrigger = labelBabyBarOct
            .rxGestureTapped
            .map { _ in ScoreboardSection.babyBar(.october) }
        
        let zoomSectionTrigger = labelZoomEmailSection
            .rxGestureTapped
            .map { _ in ScoreboardSection.zoomEmail(.mbe) }
        
        let essaysTrigger = labelEssays
            .rxGestureTapped
            .map { _ in ScoreboardSection.zoomEmail(.essays) }
        
        let mptTrigger = labelMPT
            .rxGestureTapped
            .map { _ in ScoreboardSection.zoomEmail(.mpt) }
        
        let mbeTrigger = labelMBE
            .rxGestureTapped
            .map { _ in ScoreboardSection.zoomEmail(.mbe) }
        
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
                                              filterTrigger: Observable.merge(
                                                proBarFebTrigger,
                                                proBarJulTrigger,
                                                babyBarSectionTrigger,
                                                babyBarJuneTrigger,
                                                babyBarOctTrigger,
                                                zoomSectionTrigger,
                                                essaysTrigger,
                                                mptTrigger,
                                                mbeTrigger
                                              ))
        
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .data
            .asDriverOnErrorJustComplete()
            .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),
         output
            .filterInvoked
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [unowned self] filterType in
                labelMBE.textColor = Constants.PrimaryTextColor
                labelMPT.textColor = Constants.PrimaryTextColor
                labelEssays.textColor = Constants.PrimaryTextColor
                labelBabyBarJun.textColor = Constants.PrimaryTextColor
                labelBabyBarOct.textColor = Constants.PrimaryTextColor
                labelProBarFeb.textColor = Constants.PrimaryTextColor
                labelProBarJuly.textColor = Constants.PrimaryTextColor
                labelBabyBarSection.textColor = Constants.PrimaryTextColor
                labelZoomEmailSection.textColor = Constants.PrimaryTextColor
                
                switch filterType {
                case .barExamFeb:
                    zoomEmailContainerView.isHidden = true
                    babyBarContainerView.isHidden = true
                    labelProBarFeb.textColor = .white
                    highlightViewLeading.constant = 8
                case .barExamJuly:
                    zoomEmailContainerView.isHidden = true
                    babyBarContainerView.isHidden = true
                    labelProBarJuly.textColor = .white
                    highlightViewLeading.constant = highlightView.bounds.width + 8
                case .babyBar(let item):
                    babyBarContainerView.isHidden = false
                    zoomEmailContainerView.isHidden = true
                    labelBabyBarSection.textColor = .white
                    highlightViewLeading.constant = highlightView.bounds.width * 2 + 8
                    switch item {
                    case .june:
                        labelBabyBarJun.textColor = .white
                        babyBarHighlightViewLeading.constant = 8
                    case .october:
                        labelBabyBarOct.textColor = .white
                        babyBarHighlightViewLeading.constant = babyBarHighlightView.bounds.width + 8
                    }
                case .zoomEmail(let item):
                    zoomEmailContainerView.isHidden = false
                    babyBarContainerView.isHidden = true
                    labelZoomEmailSection.textColor = .white
                    highlightViewLeading.constant = highlightView.bounds.width * 3 + 8
                    switch item {
                    case .mbe:
                        labelMBE.textColor = .white
                        zoomEmailHighlightViewLeading.constant = 8
                    case .essays:
                        labelEssays.textColor = .white
                        zoomEmailHighlightViewLeading.constant = zoomEmailHighlightView.bounds.width + 8
                    case .mpt:
                        labelMPT.textColor = .white
                        zoomEmailHighlightViewLeading.constant = zoomEmailHighlightView.bounds.width * 2 + 8
                    }
                }
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }),
         output
            .userProfile
            .unwrap()
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] profile in
                self?.labelUserName.text = IsEnableLogin ? profile.email : "Newcomer"
                self?.labelUserPosition.text = IsEnableLogin ? (profile.lastSectionName ?? "N/A") : ""
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
        collectionContainerView.backgroundColor = Constants.BackgroundColor
        collectionContainerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { $0.edges.equalTo(collectionContainerView.snp.edges) }
    }
}
