//
//  HomepageViewController.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 4/15/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class HomepageViewController: UIViewController {
  
  /// Used to segue to the tutorial sequence if it hasn't been completed.
  override func viewDidLoad() {
    super.viewDidLoad()
    if !UserDefaults.standard.bool(forKey: UserDefaultsConstants.tutorialCompletedKey) {
      performSegue(withIdentifier: "homepageToTutorial", sender: nil)
    }
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
  
  /// Used to provide the urls to be shown in the webview depending on the button tapped.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let webVC = segue.destination as? WebViewController {
      if segue.identifier == "homepageToCalendarWebView" {
        webVC.passedInTitle = "Calendar"
        webVC.passedInURL = URL(string: URLConstants.schoolCalendarURL)
      } else if segue.identifier == "homepageToBulletinWebView" {
        webVC.passedInTitle = "Daily Bulletin"
        webVC.passedInURL = URL(string: URLConstants.dailyBulletinURL)
      } else if segue.identifier == "homepageToHHScheduleWebView" {
        webVC.passedInTitle = "HH Schedule"
        webVC.passedInURL = URL(string: URLConstants.hhScheduleURL)
      } else if segue.identifier == "homepageToVideosWebView" {
        webVC.passedInTitle = "Videos"
        webVC.passedInURL = URL(string: URLConstants.videosURL)
      }
    }
  }
}
