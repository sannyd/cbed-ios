//
//  PreviewWebViewViewController.swift
//  CBED
//
//  Created by Jimmy Hoang on 17/06/2021.
//

import UIKit
import RxSwift
import RxCocoa
import WebKit

final class PreviewWebViewViewController: UIViewController {
    
    // MARK: - IBOutlets
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var labelTitle: UILabel!
    
    // MARK: - Properties
    
    var viewModel: PreviewWebViewViewModel!
    var disposeBag = DisposeBag()
    
    private var webview: WKWebView!
    
    // MARK: - Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupWebView()
        bindViewModel()
    }
    
    private func setupWebView() {
        let configuration = WKWebViewConfiguration()
        webview = WKWebView(frame: .zero, configuration: configuration)
        webview.navigationDelegate = self
        webview.uiDelegate = self
        containerView.addSubview(webview)
        webview.snp.makeConstraints {
            $0.edges.equalTo(containerView.snp.edges)
        }
        
    }
    
    deinit {
        logDeinit()
    }
    
    // MARK: - Methods
    
    func bindViewModel() {
        let input = PreviewWebViewViewModel.Input()
        let output = viewModel.transform(input, disposeBag: disposeBag)
        
        [output
            .usefulLinkURL
            .drive(onNext: { [weak self] url in
                self?.webview.load(URLRequest(url: url))
            }),
         webview
            .rx
            .observe(\.title)
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self] title in
                self?.labelTitle.text = title
            })]
            .forEach { $0.disposed(by: disposeBag) }
    }
}

extension PreviewWebViewViewController: WKNavigationDelegate, WKUIDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {

            // open in current view
            webView.load(navigationAction.request)

            // don't return a new view to build a popup into (the default behavior).
            return nil;
        }
}
