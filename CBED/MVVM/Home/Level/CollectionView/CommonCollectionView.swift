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
    func populateData(_ data: T)
}


class CommonCollectionView<T: SectionModelType, C: CellType>: UICollectionView, UICollectionViewDelegateFlowLayout {
    private let disposeBag = DisposeBag()
    
    private var cellHeight: CGFloat!
    private var cellWidth: CGFloat!
    private var lineSpacing: CGFloat!
    
    lazy var rxDatasource: RxCollectionViewSectionedReloadDataSource<T> = {
        return RxCollectionViewSectionedReloadDataSource<T> { datasource, collectionView, indexPath, item in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: C.nibName(), for: indexPath) as! C
            cell.populateData(item as! C.T)
            
            return cell
        }
    }()
    
    convenience init(cellHeight: CGFloat,
                     cellWidth: CGFloat,
                     lineSpacing: CGFloat) {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        self.init(frame: .zero, collectionViewLayout: layout)
        
        self.cellHeight = cellHeight
        self.cellWidth = cellWidth
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
        indicator.tintColor = .lightGray
        refreshControl = indicator
    }
    
    private func setupCollectionView() {
        register(C.nib(), forCellWithReuseIdentifier: C.nibName())
        rx.setDelegate(self).disposed(by: disposeBag)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return .init(width: cellWidth, height: cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return lineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
