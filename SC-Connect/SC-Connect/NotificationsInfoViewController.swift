//
//  NotificationsInfoViewController.swift
//  Shorecrest-Connect
//
//  Created by Simon Acker on 9/6/16.
//  Copyright © 2016 Shorecrest Computer Science. All rights reserved.
//

import UIKit
import UserNotifications // For showing user notifications request prompt

class NotificationsInfoViewController: UIViewController {

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
  
  /// Called when the user taps no thanks button.
  @IBAction func didTapNoThanks(_ sender: AnyObject) {
    let alertController = UIAlertController(title: "Leave notifications off?", message: "You will miss updates about sports, events, and messages from other students.", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Leave Off", style: .cancel, handler: { [weak self] (alert) in
      self?.stepForwardInTutorial()
    }))
    alertController.addAction(UIAlertAction(title: "Turn On", style: .default, handler: { [weak self] (alert) in
      self?.didTapGetNotified("" as AnyObject)
    }))
    present(alertController, animated: true, completion: nil)
  }
  
  /// Called when user taps get notified button.
  @IBAction func didTapGetNotified(_ sender: AnyObject) {
    UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
      if granted {
        Log("Remote Notification permission granted.")
        UIApplication.shared.registerForRemoteNotifications() // Registers for notifications and, if successful, updates the server
      } else {
        Log("Remote Notification permission not granted.")
      }
    }
    stepForwardInTutorial()
  }
  
  /// Used to segue to the next view controller in the tutorial sequence.
  func stepForwardInTutorial() {
    performSegue(withIdentifier: "notificationsInfoToBasicUsage", sender: nil)
  }
}
