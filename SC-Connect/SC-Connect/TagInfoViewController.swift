//
//  TagInfoViewController.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 2/8/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import UIKit

class TagInfoViewController: UITableViewController {
  
  @IBOutlet weak var colorPickerCell: ColorPickerTableViewCell!
  @IBOutlet weak var messagesCountLabel: UILabel!
  @IBOutlet weak var subscriberCountLabel: UILabel!
  @IBOutlet weak var subscriptionButton: UIButton!
  var passedTag = Tag()
  
  /// Used to set the navigation title, setup the cells to reflect the passed in tag, and add the notification center observer.
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "\(passedTag.tagName) Info"
    colorPickerCell.delegate = self
    colorPickerCell.setCheckedColor(colorIndex: passedTag.colorIndex)
    messagesCountLabel.text = "Messages: \(passedTag.messageCount)"
    getSubscriberCount()
    updateSubscriptionButtonCell()
    NotificationCenter.default.addObserver(self, selector: #selector(updateSubscriptionButtonCell), name: NSNotification.Name(rawValue: NotificationCenterConstants.subscriptionsChangedKey), object: nil)
  }
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Called when the subscribe/unsubscribe button is tapped.
  @IBAction func didTapSubscriptionButton(_ sender: Any) {
    let tagName = passedTag.tagName
    if UserManager.shared.userSignedIn() {
      if UserManager.shared.isSubscribedTo(tagName: tagName) {
        let subscriptionChangeAlertController = UIAlertController(title: "Do you want to unsubscribe from \(tagName)?", message: "By unsubscribing, \(tagName) will no longer show up in your subscriptions and will stop sending you notifications.", preferredStyle: .alert)
        subscriptionChangeAlertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
          UserManager.shared.unsubscribeFrom(tagName: tagName)
        }))
        subscriptionChangeAlertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(subscriptionChangeAlertController, animated: true, completion: nil)
      } else {
        let subscriptionChangeAlertController = UIAlertController(title: "Do you want to subscribe to \(tagName)?", message: "By subscribing, \(tagName) will show up in your subscriptions and send you notifications if you have them enabled.", preferredStyle: .alert)
        subscriptionChangeAlertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
          UserManager.shared.subscribeTo(tagName: tagName)
        }))
        subscriptionChangeAlertController.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
        present(subscriptionChangeAlertController, animated: true, completion: nil)
      }
    } else {
      present(UserManager.shared.notSignedInAlertController(), animated: true, completion: nil)
    }
  }
  
  /// Updates the subscription button cell to reflect the current subscription status.
  func updateSubscriptionButtonCell() {
    if UserManager.shared.isSubscribedTo(tagName: passedTag.tagName) {
      DispatchQueue.main.async { [weak self, tagName = passedTag.tagName] in
        self?.subscriptionButton.setTitle("Unsubscribe from \(tagName)", for: .normal)
        self?.subscriptionButton.setTitleColor(UIColor.red, for: .normal) //destructive look
      }
    } else {
      DispatchQueue.main.async { [weak self, tagName = passedTag.tagName] in
        self?.subscriptionButton.setTitle("Subscribe to \(tagName)", for: .normal)
        self?.subscriptionButton.setTitleColor(UIColor.blue, for: .normal)
      }
    }
  }
  
  /// Downloads and updates the ui to show the current subscriber count for the tag.
  func getSubscriberCount() {
    SCConnectAPI.REST.Tags.getSubscriberCountForTagWith(name: passedTag.tagName, completion: { [weak self] (subscriberCount) in
      if subscriberCount != nil {
        self?.passedTag.subscriberCount = subscriberCount!
        DispatchQueue.main.async { [weak self] in
          self?.subscriberCountLabel.text = "Subscribers: \(subscriberCount!)"
        }
      }
    })
  }
}

extension TagInfoViewController: ColorPickerTableViewCellDelegate {
  
  /// Used to update the color index of the tag to reflect the user's selection.
  func didTap(colorIndex: Int) {
    if UserManager.shared.userSignedIn() {
      if UserManager.shared.isSubscribedTo(tagName: passedTag.tagName) {
        UserManager.shared.updateColorFor(tagName: passedTag.tagName, to: colorIndex, completion: { [weak self] (success) in
          if success {
            self?.passedTag.colorIndex = colorIndex
            DispatchQueue.main.async { [weak self] in
              self?.colorPickerCell.setCheckedColor(colorIndex: colorIndex)
            }
          }
        })
      } else {
        present(UserManager.shared.notSubscribedAlertController(tagName: passedTag.tagName), animated: true, completion: nil)
      }
    } else {
      present(UserManager.shared.notSignedInAlertController(), animated: true, completion: nil)
    }
  }
}
