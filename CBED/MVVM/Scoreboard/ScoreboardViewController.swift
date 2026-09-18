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

    // MARK: - IBOutlets (tier 1 — exam cycle chips, horizontal scroll row)
    // Replaces the prior UISegmentedControl whose compressed titles
    // truncated "Baby Bar Jun" and "Email & Zoom" on small screens.
    @IBOutlet weak var examCycleScrollView: UIScrollView!
    @IBOutlet weak var examCycleStack: UIStackView!

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
        // Tier 1: exam cycle chips — each chip in the storyboard
        // scroll row is wired to its own ExamCycle enum case, mirroring
        // the section-chip pattern below. The default selection is
        // `.emailZoom` (the leftmost chip), styled as selected at
        // first render and used to drive the initial data cohort.
        let examCycleTrigger = PublishRelay<ExamCycle>()
        wireExamCycleChips(to: examCycleTrigger)
        // Fire the trigger immediately so the view-model sees the
        // initial selection (even though its BehaviorRelay also starts
        // at `.emailZoom`, this guarantees both layers agree on the
        // very first emission and exercises any side-effects that
        // listen to `examCycleTrigger`).
        examCycleTrigger.accept(.emailZoom)

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
            tutorsTrigger: tutorsButton.rx.tap.asObservable(),
            tutorsSheetVisibility: tutorsVisibilityRelay.asObservable()
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
                .drive(errorBinding),

            output.availableSections
                .asDriverOnErrorJustComplete()
                .drive(onNext: { [weak self] available in
                    self?.applyAvailableSections(available)
                }),

            output.selectedSection
                .asDriverOnErrorJustComplete()
                .distinctUntilChanged()
                .drive(onNext: { [weak self] selected in
                    // Sync the chip row's active styling to the view-model's
                    // sectionFilter — including the auto-reset path where
                    // a grading-only filter snaps back to MBE during a
                    // cycle change.
                    self?.refreshChipSelection(selected)
                })
        ]
        .forEach { $0.disposed(by: disposeBag) }

        // V11.1: belt-and-braces guarantee that the section chip row's
        // MBE chip is styled as active on first launch, regardless of
        // whether the `output.selectedSection` driver actually delivers
        // its initial `.mbe` value before the first layout pass. This
        // also pushes the explicit `.mbe` value through `chipTrigger`
        // so the view-model's `sectionFilter` relay receives the tap
        // (the relay already starts at `.mbe`, but the trigger fires
        // any other side-effects that listen on `sectionFilterTrigger`).
        refreshChipSelection(.mbe)
        chipTrigger.accept(.mbe)
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
        // V11.1 (defensive): force clipping at the runtime level so the
        // card can never let its avatar bleed past the rounded corner,
        // even if some future storyboard edit drops clipsSubviews="YES".
        // Symmetric horizontal pinning (leading+trailing = safeArea ± 16)
        // is already set in the storyboard; no width constraint is set on
        // the card, so the symmetric edges govern the width.
        countdownContainerView.clipsToBounds = true
        countdownContainerView.layer.masksToBounds = true
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
        // Note: the legacy "All" chip was removed in V11.1 — MBE is now the leftmost
        // and the default selection.
        let mapping: [(String, SectionFilter)] = [
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

            // V11.1: capture direct references to the two grading-only
            // chips so we can hide them synchronously without Rx. Done
            // here while we already have the title match in hand.
            switch match.1 {
            case .essays: essaysChipButton = button
            case .mpt:    mptsChipButton = button
            default:      break
            }

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

        // Ensure MBE starts selected at first render so the chip row has a
        // visible active state even before the user taps anything.
        //
        // IMPORTANT: assign `sectionChipButtons` BEFORE calling
        // `refreshChipSelection` — the helper has an early-return
        // guard on `!sectionChipButtons.isEmpty`, so calling it first
        // would be a no-op and leave the section chips unstyled on
        // launch (this was a real bug — the section row rendered with
        // no active chip until the user tapped one).
        sectionChipButtons = chipsByFilter
        refreshChipSelection(.mbe)
    }

    /// All section-filter chips keyed by their SectionFilter enum case.
    /// Populated by `wireChipButtons`; nil-safe in `refreshChipSelection`.
    private var sectionChipButtons: [SectionFilter: CustomBorderButton] = [:]

    /// V11.1: direct references to the two grading-only chips (Essays,
    /// M/PTs). Captured during `wireChipButtons` so we can hide them
    /// synchronously at viewDidLoad time WITHOUT depending on the view
    /// model's Rx pipeline. This is the spec's required "hard" hide —
    /// it runs before any driver can emit, so the chips are gone from
    /// frame 1 on standard exam cycles.
    private weak var essaysChipButton: CustomBorderButton?
    private weak var mptsChipButton: CustomBorderButton?

    /// V11.1: the exam cycle the UI is currently displaying. Mirrors
    /// the view-model's `examCycle` relay but lives in the view layer
    /// so the grading-chip visibility toggle has no Rx dependency and
    /// runs synchronously at viewDidLoad + on each chip tap.
    /// Default is `.emailZoom` — the spec asks for Email & Zoom to be
    /// the first chip and the default-selected cycle on launch.
    private var currentExamCycle: ExamCycle = .emailZoom

    /// V11.1: drives the view-model's `tutorsSheetVisibility` input so
    /// it knows when to surface the grading-only chips (Essays, M/PTs).
    private let tutorsVisibilityRelay = BehaviorRelay<Bool>(value: false)

    // MARK: - Exam cycle chips (tier 1)

    /// All exam-cycle chips keyed by their ExamCycle enum case.
    /// Populated by `wireExamCycleChips`; nil-safe in `refreshExamChipSelection`.
    private var examCycleChips: [ExamCycle: CustomBorderButton] = [:]

    /// Wire each exam-cycle chip in the storyboard scroll row to its
    /// ExamCycle enum case. Mirrors `wireChipButtons` for the section
    /// filter row directly below — same pill styling, same selection
    /// pattern. Defaults the selection to `.emailZoom` (leftmost) at
    /// first render; the visual order in the storyboard is
    /// Email & Zoom / July / Feb / Baby Bar Jun / Baby Bar Oct.
    /// Title strings must match the buttons' `state.normal.title`
    /// in the storyboard.
    private func wireExamCycleChips(to relay: PublishRelay<ExamCycle>) {
        let mapping: [(String, ExamCycle)] = [
            ("July", .july),
            ("Feb", .feb),
            ("Baby Bar Jun", .babyBarJun),
            ("Baby Bar Oct", .babyBarOct),
            ("Email & Zoom", .emailZoom),
        ]

        var chipsByCycle: [ExamCycle: CustomBorderButton] = [:]

        for subview in examCycleStack.arrangedSubviews {
            guard let button = subview as? CustomBorderButton else { continue }
            guard let title = button.title(for: .normal) else { continue }
            guard let match = mapping.first(where: { $0.0 == title }) else { continue }

            // Reuse the same pill styling as the section chip row.
            styleChipAsPill(button)
            chipsByCycle[match.1] = button

            button.rx.tap
                .map { _ in match.1 }
                .bind(to: relay)
                .disposed(by: disposeBag)
        }

        relay
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] selected in
                guard let self = self else { return }
                self.refreshExamChipSelection(selected)
                // V11.1: also update view-layer exam-cycle state and
                // hard-hide / show the grading-only chips synchronously.
                // This is independent of the view-model's Rx pipeline so
                // it always fires — even if `output.availableSections`
                // never emits for any reason.
                self.currentExamCycle = selected
                self.refreshGradingChipsVisibility()
            })
            .disposed(by: disposeBag)

        // Ensure Email & Zoom starts selected at first render — it's
        // the leftmost chip in the storyboard and the spec-mandated
        // default cycle on launch. This drives both the view-layer
        // (chip styling + grading-chips visibility) and the
        // view-model (data filter = email_zoom cohort) at boot.
        //
        // IMPORTANT: assign `examCycleChips` BEFORE calling
        // `refreshExamChipSelection` — the helper has an early-return
        // guard on `!examCycleChips.isEmpty`, so calling it first
        // would be a no-op and leave the cycle chips unstyled on
        // launch.
        examCycleChips = chipsByCycle
        refreshExamChipSelection(.emailZoom)
        // V11.1: apply the initial hard-hide/show so the grading chips
        // reflect the .emailZoom default (i.e., they're VISIBLE on
        // first render — the user must see Essays and M/PTs by default).
        refreshGradingChipsVisibility()
    }

    /// Apply active/inactive styling to each exam-cycle chip based on
    /// the current selection. Same logic as `refreshChipSelection` for
    /// section chips, but with a different dictionary key.
    private func refreshExamChipSelection(_ selected: ExamCycle) {
        guard !examCycleChips.isEmpty else { return }
        for (cycle, button) in examCycleChips {
            let isActive = (cycle == selected)
            if isActive {
                button.setTitleColor(.white, for: .normal)
                button.enabledBackgroundColor = Constants.PrimaryBlue
                button.borderColor = Constants.PrimaryBlue
            } else {
                button.setTitleColor(Constants.PrimaryTextColor, for: .normal)
                button.enabledBackgroundColor = .clear
                button.borderColor = Constants.ColorA2A2A2
            }
            button.updateView()
        }
    }

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

    /// V11.1: hide/show each section chip according to the active
    /// (exam cycle, Tutors sheet visibility) tuple supplied by the view
    /// model. The view model has already auto-reset the active filter
    /// back to MBE if it became ineligible, so we only need to update
    /// each chip button's `isHidden` and re-flow the stack.
    ///
    /// UIStackView treats hidden arrangedSubviews as if they're not in
    /// the layout — calling `isHidden = true` on a chip collapses the
    /// empty space so the remaining chips sit flush against each other.
    /// We then scroll the stack to the start so the user sees the new
    /// chip set from the left edge.
    private func applyAvailableSections(_ available: [SectionFilter]) {
        guard !sectionChipButtons.isEmpty else { return }
        let availableSet = Set(available)
        for (filter, button) in sectionChipButtons {
            // Always-visible MBE must never be hidden; otherwise gate on
            // membership in the available set.
            let shouldShow = (filter == .mbe) || availableSet.contains(filter)
            if button.isHidden == shouldShow { continue }
            button.isHidden = !shouldShow
        }
        // Force the stack to re-layout immediately so the chip widths
        // settle before we re-snap the scroll position.
        sectionFilterStack.setNeedsLayout()
        sectionFilterStack.layoutIfNeeded()
        // Reset horizontal scroll to the leftmost chip so the user
        // sees the full updated row from the beginning.
        sectionFilterScrollView.setContentOffset(
            .init(x: 0, y: sectionFilterScrollView.contentOffset.y),
            animated: true
        )
    }

    /// V11.1: hard-hide / show the two grading-only chips (Essays,
    /// M/PTs) directly via the `essaysChipButton` + `mptsChipButton`
    /// outlets. No Rx pipeline — this is the synchronous, view-layer
    /// defensive path that the spec calls out: regardless of whether
    /// the view model's `availableSections` Driver fires, these chips
    /// are guaranteed to be hidden on every standard cycle from frame 1.
    ///
    /// Called from `viewDidLoad` (initial `.july` cycle) and from the
    /// exam-cycle chip tap so we react the moment the user picks a new
    /// Hide / show the secondary chips based on the active exam cycle.
    /// V11.1.1: Baby Bar candidates only get MBE drills — NextGen chips
    /// (NG 1-Choice, NG 2-Choice, IQS Counseling, IQS Drafting, SPT, LRPT),
    /// grading-only chips (Essays, M/PTs), AND the Tutors trigger button
    /// must ALL be hidden for the Baby Bar Jun / Baby Bar Oct cycles.
    /// UIStackView's "hidden arrangedSubviews collapse" rule closes the
    /// gap automatically; no whitespace left behind.
    ///
    /// Called from `viewDidLoad` (initial `.emailZoom` cycle — currentExamCycle
    /// is set by `refreshExamChipSelection(.emailZoom)` earlier in viewDidLoad)
    /// and from the exam-cycle chip tap so we react the moment the user picks
    /// a new top tab.
    private func refreshGradingChipsVisibility() {
        let isBabyBar = (currentExamCycle == .babyBarJun
                         || currentExamCycle == .babyBarOct)
        let isEmailZoom = (currentExamCycle == .emailZoom)

        // Grading-only chips: Essays + M/PTs. Visible on Email & Zoom only.
        essaysChipButton?.isHidden = !isEmailZoom
        mptsChipButton?.isHidden   = !isEmailZoom

        // NextGen chips + MBE: hidden for Baby Bar EXCEPT the MBE chip,
        // which must always be visible. Visible everywhere else,
        // including standard July / Feb + Email & Zoom.
        for (filter, button) in sectionChipButtons {
            if button === essaysChipButton || button === mptsChipButton {
                continue  // already handled above
            }
            button.isHidden = isBabyBar ? (filter != .mbe) : false
        }
        tutorsButton?.isHidden = isBabyBar

        // Force the stack to reflow immediately so the chips collapse
        // their layout footprint before the user perceives them.
        sectionFilterStack.setNeedsLayout()
        sectionFilterStack.layoutIfNeeded()
        // Snap horizontal scroll back to the start so the user sees
        // the updated row from the leftmost chip with no orphaned
        // scroll position from a previously-hidden chip.
        sectionFilterScrollView.setContentOffset(
            .init(x: 0, y: sectionFilterScrollView.contentOffset.y),
            animated: false
        )
    }

    // MARK: - Tutors sheet

    private func presentTutorsSheet(tutors: [ScoreM]) {
        let vc = TutorsSheetViewController(tutors: tutors)
        let nav = UINavigationController(rootViewController: vc)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        // V11.1: emit visibility events so the view model can decide
        // whether to surface the grading-only chips. Present happens
        // synchronously enough that we emit `true` BEFORE present() and
        // then subscribe to the nav's dismissal to emit `false`.
        tutorsVisibilityRelay.accept(true)
        // Ensure we reset to `false` even if the dismissal happens
        // through a non-standard path (drag-to-dismiss, swipe, etc.).
        nav.presentationController?.delegate = TutorsSheetObserver.shared
        TutorsSheetObserver.shared.onDismiss = { [weak self] in
            self?.tutorsVisibilityRelay.accept(false)
        }
        // V11.1: synchronous defensive show of the grading chips while
        // the Tutors sheet is on screen. The view-model will also push
        // this through `output.availableSections`, but we make it
        // immediate so the user sees the chips the instant the sheet
        // appears.
        essaysChipButton?.isHidden = false
        mptsChipButton?.isHidden   = false
        sectionFilterStack.setNeedsLayout()
        sectionFilterStack.layoutIfNeeded()
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
