//
//  LevelCollectionView.swift
//  CBED
//
//  Created by Jimmy Hoang on 13/06/2021.
//

import UIKit
import RxSwift
import RxDataSources

struct CommonCollectionViewSection<T> {
    var items: [Item]
}

extension CommonCollectionViewSection: SectionModelType {
    typealias Item = T
    
    init(original: CommonCollectionViewSection<Item>, items: [Item]) {
        self = original
        self.items = items
    }
}

protocol CellType where Self: UICollectionViewCell {
    associatedtype T
    
    static var cellHeight: CGFloat { get }
    static var cellWidth: CGFloat { get }
    
    func populateData(_ data: T)
}

class CommonAnimatableCollectionView<T: AnimatableSectionModelType, C: CellType>: UICollectionView, UICollectionViewDelegateFlowLayout {
    private let disposeBag = DisposeBag()
    
    private var cellHeight: CGFloat!
    private var cellWidth: CGFloat!
    private var lineSpacing: CGFloat!
    var onScroll: ((UIScrollView) -> ())?
    
    lazy var rxDatasource: RxCollectionViewSectionedAnimatedDataSource<T> = {
        return RxCollectionViewSectionedAnimatedDataSource<T> { datasource, collectionView, indexPath, item in
            // CBED: defensive cast — if registration is broken (different nib
            // registered for C.nibName()), log via Crashlytics and return an
            // empty cell instead of crashing the whole collection view.
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: C.nibName(), for: indexPath) as? C else {
                assertionFailure("Cell cast failed for \(C.nibName()) — registration mismatch?")
                NSLog("CBED: cell cast failed for \(C.nibName()) at \(indexPath)")
                return UICollectionViewCell()
            }
            if let typedItem = item as? C.T {
                cell.populateData(typedItem)
            } else {
                assertionFailure("Item type mismatch for \(C.nibName()) — expected \(C.T.self)")
                NSLog("CBED: item type mismatch for \(C.nibName()) at \(indexPath)")
            }
            return cell
        }
    }()
    
    convenience init(lineSpacing: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = .zero
        layout.scrollDirection = .vertical
        self.init(frame: .zero, collectionViewLayout: layout)
        
        self.lineSpacing = lineSpacing
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setupCollectionView()
        setupRefreshControl()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCollectionView()
        setupRefreshControl()
    }
    
    private func setupRefreshControl() {
        let indicator = UIRefreshControl()
        indicator.tintColor = .secondaryLabel
        refreshControl = indicator
    }
    
    private func setupCollectionView() {
        backgroundView?.backgroundColor = Constants.BackgroundColor
        backgroundColor = Constants.BackgroundColor
        clipsToBounds = false
        register(C.nib(), forCellWithReuseIdentifier: C.nibName())
        rx.setDelegate(self).disposed(by: disposeBag)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: C.cellWidth,
                     height: C.cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll?(scrollView)
    }
}

class CommonCollectionView<T: SectionModelType, C: CellType>: UICollectionView, UICollectionViewDelegateFlowLayout {
    private let disposeBag = DisposeBag()
    
    private var cellHeight: CGFloat!
    private var cellWidth: CGFloat!
    private var lineSpacing: CGFloat!
    var onScroll: ((UIScrollView) -> ())?
    
    lazy var rxDatasource: RxCollectionViewSectionedReloadDataSource<T> = {
        return RxCollectionViewSectionedReloadDataSource<T> { datasource, collectionView, indexPath, item in
            // CBED: defensive cast — see CommonAnimatableCollectionView for rationale.
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: C.nibName(), for: indexPath) as? C else {
                assertionFailure("Cell cast failed for \(C.nibName()) — registration mismatch?")
                NSLog("CBED: cell cast failed for \(C.nibName()) at \(indexPath)")
                return UICollectionViewCell()
            }
            if let typedItem = item as? C.T {
                cell.populateData(typedItem)
            } else {
                assertionFailure("Item type mismatch for \(C.nibName()) — expected \(C.T.self)")
                NSLog("CBED: item type mismatch for \(C.nibName()) at \(indexPath)")
            }
            return cell
        }
    }()
    
    convenience init(lineSpacing: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = .zero
        layout.scrollDirection = .vertical
        self.init(frame: .zero, collectionViewLayout: layout)
        
        self.lineSpacing = lineSpacing
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setupCollectionView()
        setupRefreshControl()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCollectionView()
        setupRefreshControl()
    }
    
    private func setupRefreshControl() {
        let indicator = UIRefreshControl()
        indicator.tintColor = .secondaryLabel
        refreshControl = indicator
    }
    
    private func setupCollectionView() {
        backgroundView?.backgroundColor = Constants.BackgroundColor
        backgroundColor = Constants.BackgroundColor
        clipsToBounds = false
        register(C.nib(), forCellWithReuseIdentifier: C.nibName())
        rx.setDelegate(self).disposed(by: disposeBag)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: C.cellWidth,
                     height: C.cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        onScroll?(scrollView)
    }
}

class AnswerCollectionView<T: SectionModelType, C: CellType>: UICollectionView {
    private let disposeBag = DisposeBag()
    private var lineSpacing: CGFloat!
    
    lazy var rxDatasource: RxCollectionViewSectionedReloadDataSource<T> = {
        return RxCollectionViewSectionedReloadDataSource<T> { datasource, collectionView, indexPath, item in
            // CBED: defensive cast — see CommonAnimatableCollectionView for rationale.
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: C.nibName(), for: indexPath) as? C else {
                assertionFailure("Cell cast failed for \(C.nibName()) — registration mismatch?")
                NSLog("CBED: cell cast failed for \(C.nibName()) at \(indexPath)")
                return UICollectionViewCell()
            }
            if let typedItem = item as? C.T {
                cell.populateData(typedItem)
            } else {
                assertionFailure("Item type mismatch for \(C.nibName()) — expected \(C.T.self)")
                NSLog("CBED: item type mismatch for \(C.nibName()) at \(indexPath)")
            }
            return cell
        }
    }()
    
    override var intrinsicContentSize: CGSize {
        return self.contentSize
    }
    
    override var contentSize: CGSize {
        didSet {
            invalidateIntrinsicContentSize()
        }
    }
    
    override func reloadData() {
        super.reloadData()
        self.invalidateIntrinsicContentSize()
    }
    
    convenience init(lineSpacing: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        layout.scrollDirection = .vertical
        self.init(frame: .zero, collectionViewLayout: layout)
        self.lineSpacing = lineSpacing
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        backgroundView?.backgroundColor = Constants.BackgroundColor
        backgroundColor = Constants.BackgroundColor
        isScrollEnabled = false
        clipsToBounds = false
        register(C.nib(), forCellWithReuseIdentifier: C.nibName())
        
        NotificationCenter
            .default
            .rx
            .notification(UIContentSizeCategory.didChangeNotification)
            .mapToVoid()
            .subscribe(onNext: { _ in
                self.collectionViewLayout.invalidateLayout()
            })
            .disposed(by: disposeBag)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
}

class AnswerCollectionView2<T: SectionModelType, C: CellType>: UICollectionView, UICollectionViewDelegateFlowLayout {
    private let disposeBag = DisposeBag()
    private var lineSpacing: CGFloat!
    
    lazy var rxDatasource: RxCollectionViewSectionedReloadDataSource<T> = {
        return RxCollectionViewSectionedReloadDataSource<T> { datasource, collectionView, indexPath, item in
            // CBED: defensive cast — see CommonAnimatableCollectionView for rationale.
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: C.nibName(), for: indexPath) as? C else {
                assertionFailure("Cell cast failed for \(C.nibName()) — registration mismatch?")
                NSLog("CBED: cell cast failed for \(C.nibName()) at \(indexPath)")
                return UICollectionViewCell()
            }
            if let typedItem = item as? C.T {
                cell.populateData(typedItem)
            } else {
                assertionFailure("Item type mismatch for \(C.nibName()) — expected \(C.T.self)")
                NSLog("CBED: item type mismatch for \(C.nibName()) at \(indexPath)")
            }
            return cell
        }
    }()
    
    override var intrinsicContentSize: CGSize {
        return self.contentSize
    }
    
    /// V261109.1 — break the layout-invalidation cycle.
    ///
    /// The previous implementation was:
    ///
    ///     override var contentSize: CGSize {
    ///         didSet { invalidateIntrinsicContentSize() }
    ///     }
    ///     override func reloadData() {
    ///         super.reloadData()
    ///         invalidateIntrinsicContentSize()
    ///     }
    ///
    /// `UICollectionView` reassigns `contentSize` during its own layout
    /// pass, and `invalidateIntrinsicContentSize()` marks the view as
    /// needing layout. So every layout pass scheduled another layout pass,
    /// and every one of those reassigned `contentSize` again — a
    /// self-sustaining invalidation loop that pegged the main thread.
    ///
    /// Student-visible symptom: during MCQ drills the audio ping plays and
    /// the radio button turns blue, then the screen freezes — no
    /// explanation, no advance, force-quit required. The ping and the blue
    /// repaint are synchronous, so they land. The explanation is deferred
    /// (`.delay(.milliseconds(100))` in `ExamViewModel`) and needs a
    /// main-queue turn that a saturated main thread never grants.
    ///
    /// The loop lives in shared client code, so it reproduces across
    /// unrelated subjects (Evidence, Contracts). It is intermittent because
    /// it only stabilises when the self-sized row height happens to settle
    /// within UIKit's layout tolerance.
    ///
    /// The fix: never invalidate from the `contentSize` setter. Invalidate
    /// from `layoutSubviews` — a layout callback — and only when the height
    /// actually changed. The invalidation is then bounded by the data (one
    /// extra pass after a real height change) rather than by the number of
    /// layout passes, which is what makes it terminate.
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let height = contentSize.height
        guard abs(height - lastInvalidatedIntrinsicHeight) > 0.5 else { return }
        lastInvalidatedIntrinsicHeight = height
        invalidateIntrinsicContentSize()
    }
    
    /// The content height we last published as our intrinsic height.
    /// `-1` means "nothing published yet", so the first layout always
    /// publishes.
    private var lastInvalidatedIntrinsicHeight: CGFloat = -1
    
    convenience init(lineSpacing: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        // V261109.1: `sizeForItemAt` below returns an EXACT size, so the
        // self-sizing machinery must stay off. A non-zero
        // `estimatedItemSize` asks UIKit to self-size rows *and* honours a
        // `sizeForItemAt` delegate — the two disagree, the row height
        // oscillates between passes, and each oscillation dirties the
        // layout again. The sibling `CommonCollectionView` and
        // `CommonAnimatableCollectionView` already use `.zero` for exactly
        // this reason.
        layout.estimatedItemSize = .zero
        layout.scrollDirection = .vertical
        self.init(frame: .zero, collectionViewLayout: layout)
        self.lineSpacing = lineSpacing
    }
    
    override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCollectionView()
    }
    
    private func setupCollectionView() {
        backgroundView?.backgroundColor = Constants.BackgroundColor
        backgroundColor = Constants.BackgroundColor
        isScrollEnabled = false
        clipsToBounds = false
        register(C.nib(), forCellWithReuseIdentifier: C.nibName())
        
        NotificationCenter
            .default
            .rx
            .notification(UIContentSizeCategory.didChangeNotification)
            .mapToVoid()
            .subscribe(onNext: { _ in
                // V261109.1 — the font scale may have changed, so every
                // cached measurement is stale. Drop them BEFORE
                // invalidating the layout, otherwise `sizeForItemAt`
                // re-measures against the old font and the row heights
                // disagree with the cells.
                self.invalidateRowHeightCache()
                self.collectionViewLayout.invalidateLayout()
            })
            .disposed(by: disposeBag)
        delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
    
    /// V261109.1 — drop every cached measurement.
    ///
    /// Called when the text-size scale changes, which is the only
    /// non-content input to the measurement.
    private func invalidateRowHeightCache() {
        cachedRowHeights.removeAll()
        cachedRowHeightFontScale = -1
    }
    
    /// V261109.1 — cache the measured row height.
    ///
    /// `sizeForItemAt` is called on EVERY layout pass, and the previous
    /// implementation allocated a fresh `UILabel`, applied the app's font
    /// scaling to it, and ran `sizeThatFits` each time. Because the
    /// measuring label is a throwaway, `scaledFont(style:)` re-derives the
    /// base font through `UIFont.appFont`/associated objects on every call,
    /// and the measured height could differ from the real cell's height —
    /// which is what made the row height oscillate and kept the layout
    /// permanently dirty.
    ///
    /// The cache is keyed by the answer's text, so it is invalidated
    /// naturally when the question's choices change, and by the app's font
    /// scale, so it is invalidated when the student changes text size.
    private var cachedRowHeights: [String: CGFloat] = [:]
    private var cachedRowHeightFontScale: CGFloat = -1
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Defensive: a forced cast here traps (a Swift runtime trap is not
        // an NSException, so it would not reach the Crashlytics handler).
        // Fall back to a zero size rather than taking the app down.
        guard let data = rxDatasource.sectionModels[indexPath.section].items[indexPath.item] as? SelectableAnswer else {
            return .zero
        }
        
        let labelWidth: CGFloat = UIScreen.main.bounds.width - 30 - 30 - 8 - 35
        let width = UIScreen.main.bounds.width - 30 - 30
        let text = data.answer.content ?? ""
        let fontScale = Storage.appFontSize.scale
        
        if cachedRowHeightFontScale != fontScale {
            cachedRowHeights.removeAll()
            cachedRowHeightFontScale = fontScale
        }
        
        let height: CGFloat
        if let cached = cachedRowHeights[text] {
            height = cached
        } else {
            let maxLabelSize = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
            let label = UILabel()
            label.numberOfLines = 0
            label.scaledFont(style: .body)
            label.text = text
            height = label.sizeThatFits(maxLabelSize).height + 16 + 16
            cachedRowHeights[text] = height
        }
        
        return .init(width: width, height: height)
    }
}
