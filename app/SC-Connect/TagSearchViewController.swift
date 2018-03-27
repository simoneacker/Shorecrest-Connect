//
//  TagSearchViewController.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 3/8/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import UIKit

class TagSearchViewController: UITableViewController {
  
  @IBOutlet weak var tagSearchBar: UISearchBar!
  var allTagSearchResults = [Tag]()
  
  /// Used to set the search bar delegate, setup the row heights for the table view, setup the pull-down-to-refresh control, and add the notification center observers.
  override func viewDidLoad() {
    super.viewDidLoad()
    tagSearchBar.delegate = self
    tableView.estimatedRowHeight = tableView.rowHeight
    tableView.rowHeight = UITableViewAutomaticDimension
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshTags), name: NSNotification.Name(rawValue: NotificationCenterConstants.tagColorChangedKey), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshTags), name: NSNotification.Name(rawValue: NotificationCenterConstants.newMessagePostedKey), object: nil)
    NotificationCenter.default.addObserver(self, selector: #selector(refreshTags), name: NSNotification.Name(rawValue: NotificationCenterConstants.lastReadMessagesChangedKey), object: nil)
  }
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Used to pass information to the destination view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "tagSearchToMessages" {
      if let messagesVC = segue.destination as? SlackMessagesViewController {
        if let tagPreviewCell = sender as? TagPreviewTableViewCell {
          messagesVC.passedTag = tagPreviewCell.previewTag ?? Tag()
        }
      }
    } else if segue.identifier == "tagSearchToTagInfo" {
      if let tagInfoVC = segue.destination as? TagInfoViewController {
        if let tagPreviewCell = sender as? TagPreviewTableViewCell {
          tagInfoVC.passedTag = tagPreviewCell.previewTag ?? Tag()
        }
      }
    }
  }
  
  /// Updates the data and ui to show the most current results for the current search.
  func refreshTags() {
    if let searchTerm = tagSearchBar.text { //searches for same term as before to refresh the previews with the updated info
      searchFor(term: searchTerm)
    }
  }
  
  /// Downloads the tags containing the search term and updates the ui to show them.
  func searchFor(term: String) {
    refreshControl?.beginRefreshing()
    SCConnectAPI.REST.Tags.getTagsContaining(searchTerm: term) { [weak self] (tags) in
      if tags != nil {
        self?.allTagSearchResults = tags!
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
        self?.tagSearchBar.resignFirstResponder()
      }
    }
  }
  
  // MARK: - UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return allTagSearchResults.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let tagPreviewCell = tableView.dequeueReusableCell(withIdentifier: "tagPreviewCell") as? TagPreviewTableViewCell {
      tagPreviewCell.previewTag = allTagSearchResults[indexPath.row]
      if let lastMessage = MessagesManager.shared.lastMessages[allTagSearchResults[indexPath.row].tagName] {
        tagPreviewCell.displayLast(message: lastMessage, unread: false) // Does not check read status on search page.
      } else {
        tagPreviewCell.displayLast(message: nil, unread: false)
        MessagesManager.shared.downloadLastMessageForTagWith(name: allTagSearchResults[indexPath.row].tagName, completion: {
          DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadData()
          }
        })
      }
      return tagPreviewCell
    }
    
    return UITableViewCell(style: .default, reuseIdentifier: nil) //if somehow gets to here, returns empty cell
  }
}

extension TagSearchViewController: UISearchBarDelegate {
  
  /// Used to search for the text inputed into the search field by the user.
  func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
    if let searchTerm = searchBar.text {
      searchFor(term: searchTerm)
    }
  }
}
