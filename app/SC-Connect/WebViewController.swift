//
//  WebViewController.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 4/25/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import WebKit

/// Controller that can load or display a link. Also, able to display a title in the navigation bar.
/// - Note: External links on webpages do not work.
class WebViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {
  
  /// The web view used to load the passed in link.
  let webView = WKWebView(frame: .zero, configuration: WKWebViewConfiguration())
  
  /// String title that should be displayed in the navigation bar along with the link.
  var passedInTitle = ""
  
  /// The URL that should be loaded and displayed.
  var passedInURL: URL?
  
  /// Used to set the view controller's view to the WKWebView and setup the ui delegate.
  override func loadView() {
    super.loadView()
    webView.uiDelegate = self
    webView.allowsBackForwardNavigationGestures = true
    webView.navigationDelegate = self
    view = webView
  }
  
  /// Used to set the title and load the passed in url.
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = passedInTitle
    if passedInURL != nil {
      let request = URLRequest(url: passedInURL!)
      webView.load(request)
    }
  }
  
  /// Used to start the network activity indicator.
  func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = true
  }
  
  /// Used to stop the network activity indicator.
  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    UIApplication.shared.isNetworkActivityIndicatorVisible = false
  }
}
