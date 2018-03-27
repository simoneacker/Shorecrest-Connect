//
//  WelcomeViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/17/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class WelcomeViewController: UIViewController {
  
  /// Used to hide navigation bar. Only hidden while this view is on screen.
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: false)
  }
  
  /// Used to show navigation bar before transition to another view.
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(false, animated: false)
  }
  
}
