//
//  BasicUsageViewController.swift
//  Shorecrest-Connect
//
//  Created by Simon Acker on 9/6/16.
//  Copyright © 2016 Shorecrest Computer Science. All rights reserved.
//

import UIKit
import AVKit // for playing tutorial video
import AVFoundation

class BasicUsageViewController: UIViewController {
  
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
  
  /// Used to mark the tutorial as completed.
  override func viewDidLoad() {
    super.viewDidLoad()
    UserDefaults.standard.set(true, forKey: UserDefaultsConstants.tutorialCompletedKey)
  }
  
  /// Used to mark the tutorial as completed and transition back to the homepage view controller.
  @IBAction func didTapDone(_ sender: UIButton) {
    UserDefaults.standard.set(true, forKey: UserDefaultsConstants.tutorialCompletedKey)
    navigationController?.popToRootViewController(animated: true)
  }
}
