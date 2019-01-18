//
//  WebViewVC.swift
//  FitBitPOC
//
//  Created by LN-iMAC-001 on 18/01/19.
//  Copyright © 2019 letsnurture. All rights reserved.
//

import UIKit
import WebKit

class WebViewVC: UIViewController {

    @IBOutlet var webView: WKWebView!
    var rightBar : UIBarButtonItem!
    var targetURL : URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.navigationDelegate = self
        loadAddressURL()
        rightBar = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.done, target: self, action: #selector(dismissView))
        self.navigationItem.setRightBarButton(rightBar, animated: true)
        // Do any additional setup after loading the view.
    }
    @objc func dismissView() {
        self.dismiss(animated: true, completion: nil)
    }
    func loadAddressURL() {
        let req = URLRequest(url: targetURL!)
        self.webView.load(req)
    }
}

extension WebViewVC : WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if let url = navigationAction.request.url, fitbitURI.contains(url.scheme!) {
            let notification = Notification(
                name: Notification.Name(rawValue: NotificationConstants.launchNotification),
                object:nil,
                userInfo:[UIApplication.LaunchOptionsKey.url:url])
            NotificationCenter.default.post(notification)
            decisionHandler(.cancel)
            self.dismissView()
            return
        }
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        self.dismissView()
    }
}
