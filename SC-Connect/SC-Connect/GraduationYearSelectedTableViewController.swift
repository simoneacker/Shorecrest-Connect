//
//  GraduationYearTableViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/13/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class GraduationYearSelectionTableViewController: UITableViewController {
  
  var availableGraduationYears = [Int]()
  
  /// Used to download the available graduation years.
  override func viewDidLoad() {
    super.viewDidLoad()
    SCConnectAPI.REST.LeaderboardScores.getAvailableGraduationYears { [weak self] (availableGraduationYears) in
      if availableGraduationYears != nil {
        self?.availableGraduationYears = availableGraduationYears!
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
      }
    }
  }
  
  // MARK: UITableViewDelegate
  
  /// Used to update the selected graduation year store and send an internal notification of the change.
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    UserManager.shared.setGraduation(year: availableGraduationYears[indexPath.row])
    tableView.reloadData() //show new checkmarked item
  }
  
  // MARK: UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return availableGraduationYears.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.textLabel?.text = "\(availableGraduationYears[indexPath.row])"
    if let selectedGraduationYear = UserManager.shared.getGraduationYear() { // Mark the currently selected graduation year
      if availableGraduationYears[indexPath.row] == selectedGraduationYear {
        cell.accessoryType = .checkmark
      }
    }
    return cell
  }
}
