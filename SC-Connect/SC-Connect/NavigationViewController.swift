//
//  NavigationViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/10/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import GoogleSignIn // for uisign in delegate

class NavigationViewController: UINavigationController, GIDSignInUIDelegate {
  
  /// Sets the navigation controller as the GIDSignInUIDelegate so sign in/sign out can be called at any time.
  override func viewDidLoad() {
    super.viewDidLoad()
    GIDSignIn.sharedInstance().uiDelegate = self
  }
}
