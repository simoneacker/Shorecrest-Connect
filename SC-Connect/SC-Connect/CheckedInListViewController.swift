//
//  CheckedInListViewController.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 4/3/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class CheckedInListViewController: UITableViewController {
  
  var passedInEvent = Event()
  var checkedInUsernames = [String]()
  
  /// Used to add a pull-down-to-refresh control and download the checked in user list.
  override func viewDidLoad() {
    super.viewDidLoad()
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshCheckedInList), for: .valueChanged)
    refreshCheckedInList()
  }
  
  /// Used to download the list of checked in users.
  func refreshCheckedInList() {
    checkedInUsernames.removeAll()
    SCConnectAPI.REST.Events.getCheckedInUserListFor(eventID: passedInEvent.eventID) { [weak self] (usernames) in
      if usernames != nil {
        self?.checkedInUsernames = usernames!
      } else {
        self?.checkedInUsernames.append("No users checked in.") // Display error message in place of usernames
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
      }
    }
  }
  
  // MARK: UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return checkedInUsernames.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.selectionStyle = .none
    cell.textLabel?.text = checkedInUsernames[indexPath.row]
    return cell
  }
}
