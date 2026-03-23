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
        setupFonts()
        textView.text = outlineText
        navTitleLabel.text = navTitle
        buttonBack.addTarget(self, action: #selector(goBack), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFonts()
    }
    
    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    private func setupFonts() {
        navTitleLabel.applyAppFontScaling()
        textView.applyAppFontScaling()
    }
}
