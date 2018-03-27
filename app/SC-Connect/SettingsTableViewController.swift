//
//  SettingsTableViewController.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 4/25/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import GoogleSignIn // for sign in/disconnect calls

class SettingsTableViewController: UITableViewController {

  @IBOutlet weak var usernameLabel: UILabel!
  @IBOutlet weak var userEmailLabel: UILabel!
  @IBOutlet weak var signInButton: UIButton!
  @IBOutlet weak var selectedGraduationYearLabel: UILabel!
  
  /// Used to update the ui to reflect currently selected graduation year and signed in Google account. Also, adds notification center observers.
  override func viewDidLoad() {
    super.viewDidLoad()
    refreshUserUI()
    refreshGraduationYearUI()
    NotificationCenter.default.addObserver(self, selector: #selector(refreshUserUI), name: NSNotification.Name(rawValue: NotificationCenterConstants.googleUserSignedInKey), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshUserUI), name: NSNotification.Name(rawValue: NotificationCenterConstants.googleUserSignedOutKey), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshGraduationYearUI), name: NSNotification.Name(rawValue: NotificationCenterConstants.selectedGraduationYearChangedKey), object: nil)
  }
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Used to prevent unauthorized access to moderator and admin pages.
  override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
    if identifier == "settingsToModerator" {
      if let isModerator = UserManager.shared.getUser()?.isModerator, isModerator {
        return true
      } else {
        present(UserManager.shared.permissionsIssueAlertController(), animated: true, completion: nil)
        return false
      }
    } else if identifier == "settingsToAdmin" {
      if let isAdmin = UserManager.shared.getUser()?.isAdmin, isAdmin {
        return true
      } else {
        present(UserManager.shared.permissionsIssueAlertController(), animated: true, completion: nil)
        return false
      }
    } else if identifier == "settingsToGraduationYearSelection" {
      if UserManager.shared.userSignedIn() {
        return true
      } else {
        present(UserManager.shared.notSignedInAlertController(), animated: true, completion: nil)
        return false
      }
    }
    
    return true
  }
  
  /// Called when the segmented control is switched.
  @IBAction func didChangeBrowserType(_ sender: UISegmentedControl) {
    tableView.reloadData()
  }
  
  /// Called when user taps sign in/out button.
  @IBAction func didTapSignIn(_ sender: UIButton) {
    if UserManager.shared.userSignedIn() {
      UserManager.shared.signOut()
    } else {
      UserManager.shared.signIn()
    }
  }
  
  /// Called when the user taps notifications button.
  @IBAction func didTapNotificationsSettings(_ sender: UIButton) {
    let settingsURL = URL(string: UIApplicationOpenSettingsURLString)
    if let settingsURL = settingsURL {
      UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
    }
  }
  
  /// Used to show the most current user info on screen.
  func refreshUserUI() {
    DispatchQueue.main.async { [weak self] in
      if UserManager.shared.userSignedIn() {
        self?.usernameLabel.text = "Name: \(UserManager.shared.getUser()!.firstName) \(UserManager.shared.getUser()!.lastName)"
        self?.userEmailLabel.text = "Email: \(UserManager.shared.getUser()!.email)"
        self?.signInButton.setTitle("Sign Out", for: .normal)
        self?.signInButton.setTitleColor(.red, for: .normal)
      } else {
        self?.usernameLabel.text = "Name: No user signed in"
        self?.userEmailLabel.text = "Email: No user signed in"
        self?.signInButton.setTitle("Sign In", for: .normal)
        self?.signInButton.setTitleColor(.blue, for: .normal)
      }
    }
  }
  
  /// Used to show the selected graduation year on screen.
  func refreshGraduationYearUI() {
    DispatchQueue.main.async { [weak self] in
      if let selectedGraduationYear = UserManager.shared.getGraduationYear() {
        self?.selectedGraduationYearLabel.text = "\(selectedGraduationYear)"
      } else {
        self?.selectedGraduationYearLabel.text = "None selected"
      }
    }
  }
}
