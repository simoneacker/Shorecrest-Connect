//
//  ManageTagsTableViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/12/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class ManageTagsTableViewController: UITableViewController {
  
  /// Holds the tags once they are downloaded.
  var tags = [Tag]()
  
  /// Used to setup table view and download flagged messages.
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = 250 //overestimate
    tableView.rowHeight = UITableViewAutomaticDimension
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshTags), for: .valueChanged)
    refreshTags()
  }
  
  /// Called when the user toggles editing mode.
  @IBAction func didToggleEditingMode(_ sender: UIBarButtonItem) {
    if tableView.isEditing {
      tableView.setEditing(false, animated: true)
      sender.title = "Edit"
    } else {
      tableView.setEditing(true, animated: true)
      sender.title = "Done"
    }
  }
  
  /// Used to download and store all tags.
  func refreshTags() {
    SCConnectAPI.REST.Tags.getAllTags { [weak self] (tags) in
      if tags != nil {
        self?.tags = tags!
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
      }
    }
  }
  
  // MARK: - UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return tags.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let tagPreviewCell = tableView.dequeueReusableCell(withIdentifier: "TagPreviewCell") as? TagPreviewTableViewCell {
      tagPreviewCell.previewTag = tags[indexPath.row]
      let errorMessage = PureMessage(messageID: nil, tagName: tags[indexPath.row].tagName, postDate: Date(), postCreatorID: nil, postCreatorName: "Bot") //"Bot" is the user for the error message
      errorMessage.message = "Most recent message unavailable."
      tagPreviewCell.displayLast(message: errorMessage, unread: false)
      
      return tagPreviewCell
    }
    
    return UITableViewCell()
  }
  
  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (action, indexPath) in
      if let tagName = self?.tags[indexPath.row].tagName {
        SCConnectAPI.REST.Moderators.hideTagBy(name: tagName, completion: { [weak self] (success) in
          if success {
            let alertController = UIAlertController(title: "Deleted Successfully", message: "The tag was permanently deleted.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            DispatchQueue.main.async { [weak self] in
              self?.present(alertController, animated: true, completion: nil)
            }
          }
        })
      }
      self?.tags.remove(at: indexPath.row)
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
      }
    }
    
    return [deleteAction]
  }
}
