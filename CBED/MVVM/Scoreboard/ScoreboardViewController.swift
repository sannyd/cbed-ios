import UIKit
import RxSwift
import RxCocoa

final class ScoreboardViewController: UIViewController {

    // MARK: - IBOutlets (compact header card)
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var labelUserPosition: UILabel!
    @IBOutlet weak var countdownContainerView: UIView!
    @IBOutlet weak var labelCountdownTitle: UILabel!
    @IBOutlet weak var labelCountdownValue: UILabel!
    @IBOutlet weak var labelCountdownSubtitle: UILabel!

    // MARK: - IBOutlets (tier 1 — exam cycle segmented control)
    @IBOutlet weak var examCycleSegmentedControl: UISegmentedControl!

    // MARK: - IBOutlets (tier 2 — horizontally scrolling section chips)
    @IBOutlet weak var sectionFilterScrollView: UIScrollView!
    @IBOutlet weak var sectionFilterStack: UIStackView!

    // MARK: - IBOutlets (tutors trigger)
    @IBOutlet weak var tutorsButton: UIButton!

    // MARK: - IBOutlets (student leaderboard)
    @IBOutlet weak var collectionContainerView: UIView!

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
        configureTutorsButton()
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
        // Tier 1: exam cycle (segmented control)
        let examCycleTrigger = examCycleSegmentedControl
            .rx
            .selectedSegmentIndex
            .skip(1) // skip initial emission
            .map { idx -> ExamCycle in
                switch idx {
                case 1: return .feb
                case 2: return .babyBarJun
                case 3: return .babyBarOct
                default: return .july
                }
            }

        // Tier 2: section chips — each chip is wired to its own enum case.
        // `chip-*` outlets are connected at runtime via setupSectionFilterChips().
        let chipTrigger = PublishRelay<SectionFilter>()
        wireChipButtons(to: chipTrigger)

        // Pull-to-refresh + first load
        let pullToRefreshTrigger = collectionView
            .refreshControl!
            .rx
            .controlEvent(.valueChanged)
            .asObservable()

        let viewWillAppear = rx
            .sentMessage(#selector(UIViewController.viewWillAppear))
            .mapToVoid()

        let input = ScoreboardViewModel.Input(
            firstLoadTrigger: Observable.merge(pullToRefreshTrigger, rxViewWillAppear),
            viewWillAppear: viewWillAppear,
            examCycleTrigger: examCycleTrigger.asObservable(),
            sectionFilterTrigger: chipTrigger.asObservable(),
            tutorsTrigger: tutorsButton.rx.tap.asObservable()
        )

        let output = viewModel.transform(input, disposeBag: disposeBag)

        [
            output.data
                .asDriverOnErrorJustComplete()
                .drive(collectionView.rx.items(dataSource: collectionView.rxDatasource)),

            output.tutorsTrigger
                .asDriverOnErrorJustComplete()
                .drive(onNext: { [weak self] tutors in
                    self?.presentTutorsSheet(tutors: tutors)
                }),

            output.userProfile
                .unwrap()
                .asDriverOnErrorJustComplete()
                .drive(onNext: { [weak self] profile in
                    self?.labelUserPosition.isHidden = !IsEnableLogin
                    self?.labelUserPosition.applyScoreboardLevelColor(
                        for: IsEnableLogin ? (profile.lastSectionName ?? "N/A") : ""
                    )
                    if IsEnableLogin {
                        self?.profileImageView.loadImage(
                            with: profile.avatar,
                            placeholder: #imageLiteral(resourceName: "img_user_placeholder")
                        )
                        self?.updateCountdown(for: profile.memberPlan)
                    } else {
                        self?.profileImageView.image = #imageLiteral(resourceName: "img_user_placeholder")
                        self?.countdownContainerView.isHidden = true
                    }
                }),

            output.isLoading
                .asDriverOnErrorJustComplete()
                .drive(onNext: { [weak self] isLoading in
                    if isLoading {
                        self?.collectionView.refreshControl?.beginRefreshing()
                    } else {
                        self?.collectionView.refreshControl?.endRefreshing()
                    }
                }),

            output.error
                .asDriverOnErrorJustComplete()
                .drive(errorBinding)
        ]
        .forEach { $0.disposed(by: disposeBag) }
    }

    // MARK: - Setup

    private func setupCollectionView() {
        collectionView = CommonCollectionView<CommonCollectionViewSection<ScoreM>, ScoreCell>(lineSpacing: 14)
        collectionView.contentInset = .init(top: 12, left: 0, bottom: 30, right: 0)
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
        labelCountdownValue.font = .monospacedDigitSystemFont(ofSize: 18, weight: .bold)
        labelCountdownValue.adjustsFontSizeToFitWidth = true
        labelCountdownValue.minimumScaleFactor = 0.7
    }

    private func configureTutorsButton() {
        tutorsButton.layer.cornerRadius = 8
        tutorsButton.clipsToBounds = true
        tutorsButton.setTitleColor(.white, for: .normal)
        tutorsButton.backgroundColor = Constants.PrimaryBlue
        tutorsButton.titleLabel?.font = .boldSystemFont(ofSize: 13)
        tutorsButton.contentEdgeInsets = .init(top: 6, left: 14, bottom: 6, right: 14)
    }

    /// Wire each chip button (outlet from storyboard) to a SectionFilter enum case.
    /// The buttons live in sectionFilterStack from the storyboard; we reach them
    /// by tag (set in storyboard at design time, or via title match).
    ///
    /// Each chip is styled as a rounded pill at startup with:
    /// - cornerRadius 16 (half the chip height of 32) so it renders as a pill
    /// - 14pt horizontal contentInsets for padding around the label
    /// - transparent background + Constants.ColorA2A2A2 text in the inactive state
    /// - Constants.PrimaryBlue background + white text in the active state
    ///
    /// The currently-selected chip's style is driven reactively by
    /// `selectedSectionRelay` — see `bindViewModel()`. Every chip tap
    /// publishes a new `SectionFilter` to that relay, which flips the
    /// visual state on every other chip and updates the data stream.
    private func wireChipButtons(to relay: PublishRelay<SectionFilter>) {
        // Each chip in the storyboard has a tag equal to its SectionFilter raw value.
        // Tags are 0...n set in the XIB / storyboard; fall back to title-based match.
        let mapping: [(String, SectionFilter)] = [
            ("All", .all),
            ("MBE", .mbe),
            ("Essays", .essays),
            ("M/PTs", .mpt),
            ("NG 1-Choice", .ng1Choice),
            ("NG 2-Choice", .ng2Choice),
            ("IQS Counseling", .iqsCounseling),
            ("IQS Drafting", .iqsDrafting),
            ("SPT", .spt),
            ("LRPT", .lrpt),
        ]

        var chipsByFilter: [SectionFilter: CustomBorderButton] = [:]

        for subview in sectionFilterStack.arrangedSubviews {
            guard let button = subview as? CustomBorderButton else { continue }
            guard let title = button.title(for: .normal) else { continue }
            guard let match = mapping.first(where: { $0.0 == title }) else { continue }

            // Apply the pill styling once at startup. The active/inactive
            // styling is swapped reactively by selectedSectionRelay.
            styleChipAsPill(button)
            chipsByFilter[match.1] = button

            button.rx.tap
                .map { _ in match.1 }
                .bind(to: relay)
                .disposed(by: disposeBag)
        }

        // Drive the chip's visual state from the relay. Every chip subscribes
        // here so they all update consistently when the user picks one.
        // Exclude `.all` because initially `.all` should be selected and
        // selecting `.all` twice (e.g. user re-taps) is a no-op visually.
        relay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] selected in
                self?.refreshChipSelection(selected)
            })
            .disposed(by: disposeBag)

        // Ensure "All" starts selected at first render so the chip row has
        // a visible active state even before the user taps anything.
        refreshChipSelection(.all)
        // Keep a reference so future refreshes can iterate every chip.
        sectionChipButtons = chipsByFilter
    }

    /// All section-filter chips keyed by their SectionFilter enum case.
    /// Populated by `wireChipButtons`; nil-safe in `refreshChipSelection`.
    private var sectionChipButtons: [SectionFilter: CustomBorderButton] = [:]

    /// Apply the rounded-pill styling each chip needs to look like a pill.
    private func styleChipAsPill(_ button: CustomBorderButton) {
        // borderRadius drives layer.cornerRadius via CustomBorderButton.updateView();
        // setting both is redundant. 16 = half the chip's 32pt height → full pill.
        button.borderRadius = 16
        // inactive default; refreshChipSelection overwrites once the user picks one
        button.enabledBackgroundColor = .clear
        button.disabledBackgroundColor = .clear
        button.borderColor = Constants.ColorA2A2A2
        button.borderWidth = 1
        // Inset the title so the pill reads as wider than the label alone.
        button.contentEdgeInsets = .init(top: 6, left: 14, bottom: 6, right: 14)
        button.setTitleColor(Constants.PrimaryTextColor, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 13)
    }

    /// Apply active/inactive styling to every chip based on `selected`.
    /// The selected chip switches to PrimaryBlue background + white title;
    /// every other chip resets to a transparent background with primary-text.
    ///
    /// Note: we deliberately set `enabledBackgroundColor` directly instead
    /// of toggling `isSelected` / `isEnabled`, because CustomBorderButton
    /// swaps bg between enabled/disabled colors based on `isEnabled`. We
    /// keep every chip enabled and overwrite the `enabledBackgroundColor`
    /// to whatever role (active/inactive) this chip should play.
    private func refreshChipSelection(_ selected: SectionFilter) {
        guard !sectionChipButtons.isEmpty else { return }
        for (filter, button) in sectionChipButtons {
            let isActive = (filter == selected)
            if isActive {
                button.setTitleColor(.white, for: .normal)
                button.enabledBackgroundColor = Constants.PrimaryBlue
                button.borderColor = Constants.PrimaryBlue
            } else {
                button.setTitleColor(Constants.PrimaryTextColor, for: .normal)
                button.enabledBackgroundColor = .clear
                button.borderColor = Constants.ColorA2A2A2
            }
            button.updateView()   // CustomBorderButton refresh — reapplies bg + border
        }
    }

    // MARK: - Tutors sheet

    private func presentTutorsSheet(tutors: [ScoreM]) {
        let vc = TutorsSheetViewController(tutors: tutors)
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        present(nav, animated: true)
    }

    // MARK: - Countdown (unchanged from prior implementation)

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
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshCountdown(forMonth: month)
        }
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
            return (month: 2, title: "February Exam", subtitle: "Until the last Tuesday in February")
        case .proBarJul:
            return (month: 7, title: "July Exam", subtitle: "Until the last Tuesday in July")
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
            guard let examDate = lastTuesday(ofMonth: month, year: year) else { continue }
            if examDate >= referenceDate { return examDate }
        }
        return nil
    }

    private func lastTuesday(ofMonth month: Int, year: Int) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month + 1
        components.day = 0
        guard let lastDayOfMonth = countdownCalendar.date(from: components) else { return nil }

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
