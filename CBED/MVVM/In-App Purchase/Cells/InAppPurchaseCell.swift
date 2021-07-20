//
//  InAppPurchaseCell.swift
//  CBED
//
//  Created by Jimmy Hoang on 07/07/2021.
//

import UIKit

extension Double {
    func digit(maximumFractionDigits: Int) -> String? {
        let formatter = NumberFormatter()
        formatter.locale = Locale.init(identifier: "en_CA")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = maximumFractionDigits
        formatter.minimumFractionDigits = maximumFractionDigits
        return formatter.string(for: self)
    }
}

class InAppPurchaseCell: UICollectionViewCell, CellType {
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var subtitleView: CustomBorderView!
    @IBOutlet weak var labelSubtitle: UILabel!
    @IBOutlet weak var labelPromotionPrice: UILabel!
    @IBOutlet weak var labelRealPrice: UILabel!
    @IBOutlet weak var labelDescription: UILabel!
    
    static var cellHeight: CGFloat {
        return 100
    }
    
    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 20 - 20
    }
    
    typealias T = InAppPurchaseType

    func populateData(_ data: InAppPurchaseType) {
        labelTitle.text = data.title
        if let subtitle = data.subtitle,
           !subtitle.isEmpty {
            labelSubtitle.text = subtitle
            subtitleView.isHidden = false
        } else {
            subtitleView.isHidden = true
        }
        let promotionText = data.promotionPrice.digit(maximumFractionDigits: 2) ?? ""
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: promotionText)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle,
                                         value: 1,
                                         range: NSMakeRange(0, attributeString.length))
        labelPromotionPrice.attributedText = attributeString
        labelRealPrice.text = data.realPrice.digit(maximumFractionDigits: 2)
        
        labelDescription.text = data.descriptions.joined(separator: "\n")
    }
}
