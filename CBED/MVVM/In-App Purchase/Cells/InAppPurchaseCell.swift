//
//  InAppPurchaseCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 07/07/2021.
//

import UIKit

class InAppPurchaseCell: UICollectionViewCell, CellType {
    static var cellHeight: CGFloat {
        return 100
    }
    
    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 20 - 20
    }
    
    typealias T = InAppPurchaseType
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func populateData(_ data: InAppPurchaseType) {
        
    }
}
