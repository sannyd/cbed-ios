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
        return 90
    }
    
    static var cellWidth: CGFloat {
        return UIScreen.main.bounds.width - 20 - 20
    }
    
    typealias T = SubscriptionPlanM

    func populateData(_ data: SubscriptionPlanM) {
        labelTitle.text = data.name.title
//        if let subtitle = data.subtitle,
//           !subtitle.isEmpty {
//            labelSubtitle.text = subtitle
//            subtitleView.isHidden = false
//        } else {
//            subtitleView.isHidden = true
//        }
        let promotionText = data.name.promotionPrice.digit(maximumFractionDigits: 2) ?? ""
        let attributeString: NSMutableAttributedString =  NSMutableAttributedString(string: promotionText)
            attributeString.addAttribute(NSAttributedString.Key.strikethroughStyle,
                                         value: 1,
                                         range: NSMakeRange(0, attributeString.length))
        labelPromotionPrice.attributedText = attributeString
        labelRealPrice.text = "$\(data.price.digit(maximumFractionDigits: 2)!)"
        
        labelDescription.text = data.name.descriptions.joined(separator: "\n")
    }
}
