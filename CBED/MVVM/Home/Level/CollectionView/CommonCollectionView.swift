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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: C.nibName(), for: indexPath) as! C
            cell.populateData(item as! C.T)
            
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: C.nibName(), for: indexPath) as! C
            cell.populateData(item as! C.T)
            
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: C.nibName(), for: indexPath) as! C
            cell.populateData(item as! C.T)
            
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
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: C.nibName(), for: indexPath) as! C
            cell.populateData(item as! C.T)
            
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
        delegate = self
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let data = rxDatasource.sectionModels[indexPath.section].items[indexPath.item] as! SelectableAnswer
        let labelWidth: CGFloat = UIScreen.main.bounds.width - 30 - 30 - 8 - 35
        let maxLabelSize = CGSize(width: labelWidth, height: .greatestFiniteMagnitude)
        let label = UILabel()
        label.numberOfLines = 0
        label.scaledFont(style: .body)
        label.text = data.answer.content
        let titleLabelSize = label.sizeThatFits(maxLabelSize)
        
        return .init(width: UIScreen.main.bounds.width - 30 - 30, height: titleLabelSize.height + 16 + 16)
    }
}
