//
//  AboutViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/17/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class AboutTableViewController: UITableViewController {
  
  /// Used to pass information to the destination view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let webVC = segue.destination as? WebViewController {
      if segue.identifier == "settingsToAbout" {
        webVC.passedInTitle = "About"
        webVC.passedInURL = URL(string: URLConstants.aboutURL)
      } else if segue.identifier == "settingsToTOU" {
        webVC.passedInTitle = "Terms of Use"
        webVC.passedInURL = URL(string: URLConstants.termsOfUseURL)
      } else if segue.identifier == "settingsToEULA" {
        webVC.passedInTitle = "End User Liscense Agreement"
        webVC.passedInURL = URL(string: URLConstants.endUserLiscenseAgreementURL)
      } else if segue.identifier == "settingsToPrivacyPolicy" {
        webVC.passedInTitle = "Privacy Policy"
        webVC.passedInURL = URL(string: URLConstants.privacyPolicyURL)
      }
    }
  }
}
