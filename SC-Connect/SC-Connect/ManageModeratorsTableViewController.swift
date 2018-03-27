//
//  ManageModeratorsTableViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/13/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class ManageModeratorsTableViewController: UITableViewController {
  
  /// Holds information about each moderator.
  var moderators = [Moderator]()
  
  /// Used to setup table view and download moderators.
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = 250 //overestimate
    tableView.rowHeight = UITableViewAutomaticDimension
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshModerators), for: .valueChanged)
    refreshModerators()
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
  
  /// Used to download and store each moderator's information.
  func refreshModerators() {
    SCConnectAPI.REST.Admins.getAllModerators { [weak self] (moderators) in
      if moderators != nil {
        self?.moderators = moderators!.filter({ (moderator) -> Bool in
          if moderator.email != UserManager.shared.getUser()?.email { // Filters out the currently signed in user from the moderators array
            return true
          } else {
            return false
          }
        })
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
    return moderators.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let moderatorInfoCell = tableView.dequeueReusableCell(withIdentifier: "ModeratorInfoCell") {
      moderatorInfoCell.textLabel?.text = moderators[indexPath.row].name
      moderatorInfoCell.detailTextLabel?.text = moderators[indexPath.row].email
      
      return moderatorInfoCell
    }
    
    return UITableViewCell()
  }
  
  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let deleteAction = UITableViewRowAction(style: .destructive, title: "Demote") { [weak self] (action, indexPath) in
      if let moderatorID = self?.moderators[indexPath.row].moderatorID {
        SCConnectAPI.REST.Admins.demoteModeratorBy(id: moderatorID, completion: { [weak self] (success) in
          if success {
            let alertController = UIAlertController(title: "Demoted Successfully", message: "The moderator was demoted back to user status.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            DispatchQueue.main.async { [weak self] in
              self?.present(alertController, animated: true, completion: nil)
            }
          }
        })
      }
      self?.moderators.remove(at: indexPath.row)
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
      }
    }
    
    return [deleteAction]
  }
}
