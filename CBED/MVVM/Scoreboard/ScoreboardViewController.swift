import UIKit
import RxSwift
import RxCocoa

final class ScoreboardViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var labelUserPosition: UILabel!
    @IBOutlet weak var countdownContainerView: UIView!
    @IBOutlet weak var labelCountdownTitle: UILabel!
    @IBOutlet weak var labelCountdownValue: UILabel!
    @IBOutlet weak var labelCountdownSubtitle: UILabel!
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
    private var countdownTimer: Timer?
    private let countdownCalendar = Calendar(identifier: .gregorian)
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCountdownView()
        setupCollectionView()
        bindViewModel()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
        
        if !IsEnableLogin {
            labelUserPosition.isHidden = true
            profileImageView.image = #imageLiteral(resourceName: "img_user_placeholder")
            countdownContainerView.isHidden = true
        }
    }
    
    deinit {
        countdownTimer?.invalidate()
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
                self?.labelUserPosition.isHidden = !IsEnableLogin
                self?.labelUserPosition.applyScoreboardLevelColor(for: IsEnableLogin ? (profile.lastSectionName ?? "N/A") : "")
                if IsEnableLogin {
                    self?.profileImageView.loadImage(with: profile.avatar,
                                                     placeholder: #imageLiteral(resourceName: "img_user_placeholder"))
                    self?.updateCountdown(for: profile.memberPlan)
                } else {
                    self?.profileImageView.image = #imageLiteral(resourceName: "img_user_placeholder")
                    self?.countdownContainerView.isHidden = true
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

    private func configureCountdownView() {
        countdownContainerView.backgroundColor = Constants.SecondarySurfaceColor
        countdownContainerView.setCornerRadius(radius: 16)
        countdownContainerView.setShadow(color: Constants.CardShadowColor,
                                         opacity: 0.2,
                                         offSet: .init(width: 0, height: 8),
                                         radius: 24)
        labelCountdownValue.font = .monospacedDigitSystemFont(ofSize: 20, weight: .bold)
        labelCountdownValue.adjustsFontSizeToFitWidth = true
        labelCountdownValue.minimumScaleFactor = 0.7
    }

    private func updateCountdown(for memberPlan: MemberPlan) {
        guard let config = countdownConfiguration(for: memberPlan) else {
            countdownTimer?.invalidate()
            countdownTimer = nil
            countdownContainerView.isHidden = true
            return
        }

        countdownContainerView.isHidden = false
        labelCountdownTitle.text = config.title
        labelCountdownSubtitle.text = config.subtitle
        refreshCountdown(forMonth: config.month)
        startCountdownTimer(forMonth: config.month)
    }

    private func startCountdownTimer(forMonth month: Int) {
        countdownTimer?.invalidate()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1,
                                              repeats: true,
                                              block: { [weak self] _ in
            self?.refreshCountdown(forMonth: month)
        })
        if let countdownTimer {
            RunLoop.main.add(countdownTimer, forMode: .common)
        }
    }

    private func refreshCountdown(forMonth month: Int) {
        guard let targetDate = nextAssignedBarExamDate(forMonth: month) else {
            labelCountdownValue.text = "TBD"
            return
        }

        labelCountdownValue.text = formattedCountdown(until: targetDate)
    }

    private func countdownConfiguration(for memberPlan: MemberPlan) -> (month: Int, title: String, subtitle: String)? {
        switch memberPlan {
        case .proBarFeb:
            return (month: 2,
                    title: "February Exam",
                    subtitle: "Until the last Tuesday in February")
        case .proBarJul:
            return (month: 7,
                    title: "July Exam",
                    subtitle: "Until the last Tuesday in July")
        default:
            return nil
        }
    }

    private func formattedCountdown(until targetDate: Date, now: Date = Date()) -> String {
        let totalSeconds = max(Int(targetDate.timeIntervalSince(now)), 0)
        let days = totalSeconds / 86_400
        let hours = (totalSeconds % 86_400) / 3_600
        let minutes = (totalSeconds % 3_600) / 60
        let seconds = totalSeconds % 60

        return String(format: "%02dd %02dh %02dm %02ds", days, hours, minutes, seconds)
    }

    private func nextAssignedBarExamDate(forMonth month: Int, referenceDate: Date = Date()) -> Date? {
        let currentYear = countdownCalendar.component(.year, from: referenceDate)

        for year in [currentYear, currentYear + 1] {
            guard let examDate = lastTuesday(ofMonth: month, year: year) else {
                continue
            }

            if examDate >= referenceDate {
                return examDate
            }
        }

        return nil
    }

    private func lastTuesday(ofMonth month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 0

        guard let lastDayOfMonth = countdownCalendar.date(from: components) else {
            return nil
        }

        var date = lastDayOfMonth
        while countdownCalendar.component(.weekday, from: date) != 3 {
            guard let previousDay = countdownCalendar.date(byAdding: .day, value: -1, to: date) else {
                return nil
            }
            date = previousDay
        }

        var examComponents = countdownCalendar.dateComponents([.year, .month, .day], from: date)
        examComponents.hour = 0
        examComponents.minute = 0
        examComponents.second = 0
        return countdownCalendar.date(from: examComponents)
    }
}
