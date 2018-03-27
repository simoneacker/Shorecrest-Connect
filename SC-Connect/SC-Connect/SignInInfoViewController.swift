//
//  SignInInfoViewController.swift
//  Shorecrest-Connect
//
//  Created by Simon Acker on 9/6/16.
//  Copyright © 2016 Shorecrest Computer Science. All rights reserved.
//

import UIKit
import GoogleSignIn // for sign in/disconnect calls

class SignInInfoViewController: UIViewController {
  
  @IBOutlet weak var noThanksButton: UIButton!
  @IBOutlet weak var signInButton: UIButton!
  @IBOutlet weak var signInLoadingIndicatorView: UIActivityIndicatorView!

  /// Used to add a notification center observer.
  override func viewDidLoad() {
    super.viewDidLoad()
    NotificationCenter.default.addObserver(self, selector: #selector(stepForwardInTutorial), name: NSNotification.Name(rawValue: NotificationCenterConstants.googleUserSignedInKey), object: nil)
  }
  
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
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Called when the user taps no thanks button.
  @IBAction func didTapNoThanks(_ sender: AnyObject) {
    let alertController = UIAlertController(title: "Are you sure?", message: "You will not be able to post messages, check in to events, or upload images to fan cam if you do not sign in to a Google Account.", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Sign In Later", style: .cancel, handler: { [weak self] (alert) in
      self?.stepForwardInTutorial()
    }))
    alertController.addAction(UIAlertAction(title: "Sign In", style: .default, handler: { [weak self] (alert) in
      self?.didTapSignIn("" as AnyObject)
    }))
    present(alertController, animated: true, completion: nil)
  }
  
  /// Called when the user taps sign in button to disable the navigation buttons, start the activity indicator, and call the Google sign in api.
  @IBAction func didTapSignIn(_ sender: AnyObject) {
    noThanksButton.isEnabled = false
    signInButton.isEnabled = false
    signInLoadingIndicatorView.startAnimating()
    GIDSignIn.sharedInstance().signIn()
  }
  
  /// Used to stop the activity indicator and segue to the next view controller in the tutorial sequence.
  func stepForwardInTutorial() {
    signInLoadingIndicatorView.stopAnimating()
    performSegue(withIdentifier: "signInInfoToNotificationsInfo", sender: nil)
  }
}
