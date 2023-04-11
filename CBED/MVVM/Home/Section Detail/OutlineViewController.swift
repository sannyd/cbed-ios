//
//  OutlineViewController.swift
//  CBED
//
//  Created by Jimmy on 25/03/2023.
//

import UIKit

final class OutlineViewController: UIViewController {
    @IBOutlet weak var buttonBack: UIButton!
    @IBOutlet weak var navTitleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    
    var outlineText: String?
    var navTitle: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        textView.text = outlineText
        navTitleLabel.text = navTitle
        buttonBack.addTarget(self, action: #selector(goBack), for: .touchUpInside)
    }
    
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
}
