//
//  TagBrowserViewController.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 2/9/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import UIKit

class TagBrowserViewController: UITableViewController {
  
  @IBOutlet weak var browserTypeSegmentedControl: UISegmentedControl!
  var trendingTags = [Tag]()
  var trendingTagLastMessages = [String: SkeletonMessage]()
  
  /// Used to setup the row heights for the table view, a pull-down-to-refresh control, and the notification center observers.
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = tableView.rowHeight
    tableView.rowHeight = UITableViewAutomaticDimension
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshTags), name: NSNotification.Name(rawValue: NotificationCenterConstants.tagColorChangedKey), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshTags), name: NSNotification.Name(rawValue: NotificationCenterConstants.newMessagePostedKey), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshTags), name: NSNotification.Name(rawValue: NotificationCenterConstants.subscriptionsChangedKey), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshTags), name: NSNotification.Name(rawValue: NotificationCenterConstants.lastReadMessagesChangedKey), object: nil)
  }
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Used to pass information to the destination view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "tagBrowserToMessages" {
      if let messagesVC = segue.destination as? SlackMessagesViewController {
        if let tagPreviewCell = sender as? TagPreviewTableViewCell {
          messagesVC.passedTag = tagPreviewCell.previewTag ?? Tag()
        }
      }
    } else if segue.identifier == "tagBrowserToTagInfo" {
      if let tagInfoVC = segue.destination as? TagInfoViewController {
        if let tagPreviewCell = sender as? TagPreviewTableViewCell {
          tagInfoVC.passedTag = tagPreviewCell.previewTag ?? Tag()
        }
      }
    }
  }
  
  /// Called when the segmented control is switched.
  @IBAction func didChangeBrowserTypeSegmentedControl(_ sender: UISegmentedControl) {
    refreshTags()
  }
  
  /// Updates the data and ui to show the most current trending tags or subscriptions.
  func refreshTags() {
    if browserTypeSegmentedControl.selectedSegmentIndex == 0 {
      reloadSubscribedTags()
    } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 {
      reloadTopTags()
    }
  }
  
  /// Call a ui update.
  func reloadSubscribedTags() {
    DispatchQueue.main.async { [weak self] in
      self?.tableView.reloadData()
      self?.refreshControl?.endRefreshing()
    }
  }
  
  /// Downloads the trending tags and then calls for a ui update.
  func reloadTopTags() {
    SCConnectAPI.REST.Tags.getTopTags { [weak self] (tags) in
      if tags != nil {
        self?.trendingTags = tags!
        self?.trendingTagLastMessages.removeAll()
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
      }
    }
  }
  
  
  // MARK: - UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    if browserTypeSegmentedControl.selectedSegmentIndex == 0 && UserManager.shared.getSubscribedTags().count <= 0 { // No data messages
      let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
      noDataLabel.text = "When you subscribe to a tag, it will show up here."
      noDataLabel.numberOfLines = 0 // autolayouts to number of lines needed
      noDataLabel.textColor = UIColor.black
      noDataLabel.textAlignment = .center
      tableView.backgroundView = noDataLabel
      tableView.separatorStyle = .none
      return 0
    } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 && trendingTags.count <= 0 {
      let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
      noDataLabel.text = "No trending tags available."
      noDataLabel.numberOfLines = 0 // autolayouts to number of lines needed
      noDataLabel.textColor = UIColor.black
      noDataLabel.textAlignment = .center
      tableView.backgroundView = noDataLabel
      tableView.separatorStyle = .none
      return 0
    }
    
    tableView.backgroundView = nil // Setup to show data
    tableView.separatorStyle = .singleLine
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if browserTypeSegmentedControl.selectedSegmentIndex == 0 {
      return UserManager.shared.getSubscribedTags().count
    } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 {
      return trendingTags.count
    }
    
    return 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let tagPreviewCell = tableView.dequeueReusableCell(withIdentifier: "tagPreviewCell") as? TagPreviewTableViewCell {
      if browserTypeSegmentedControl.selectedSegmentIndex == 0 {
        tagPreviewCell.previewTag = UserManager.shared.getSubscribedTags()[indexPath.row]
        if let lastMessage = MessagesManager.shared.lastMessages[UserManager.shared.getSubscribedTags()[indexPath.row].tagName] {
          let lastReadMessageIDForTag = MessagesManager.shared.lastReadMessageIDs[UserManager.shared.getSubscribedTags()[indexPath.row].tagName] ?? 0
          let isUnread = (lastMessage.messageID > lastReadMessageIDForTag)
          tagPreviewCell.displayLast(message: lastMessage, unread: isUnread)
        } else {
          tagPreviewCell.displayLast(message: nil, unread: false)
          MessagesManager.shared.downloadLastMessageForTagWith(name: UserManager.shared.getSubscribedTags()[indexPath.row].tagName, completion: { [weak self] in
            DispatchQueue.main.async { [weak self] in
              self?.tableView.reloadData()
            }
          })
        }
      } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 {
        tagPreviewCell.previewTag = trendingTags[indexPath.row]
        if let lastMessage = MessagesManager.shared.lastMessages[trendingTags[indexPath.row].tagName] {
          tagPreviewCell.displayLast(message: lastMessage, unread: false)
        } else {
          tagPreviewCell.displayLast(message: nil, unread: false)
          MessagesManager.shared.downloadLastMessageForTagWith(name: trendingTags[indexPath.row].tagName, completion: { [weak self] in
            DispatchQueue.main.async { [weak self] in
              self?.tableView.reloadData()
            }
          })
        }
      }
      
      return tagPreviewCell
    }
    
    return UITableViewCell(style: .default, reuseIdentifier: nil)
  }
}
