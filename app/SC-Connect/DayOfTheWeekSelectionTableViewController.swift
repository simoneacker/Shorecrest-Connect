//
//  DayOfTheWeekTableViewController.swift
//  Club_Meetings
//
//  Created by Steven Zhu on 5/20/17.
//  Copyright © 2017 Steven Zhu. All rights reserved.
//

import UIKit

class DayOfTheWeekSelectionTableViewController: UITableViewController {
  
  let dayOfTheWeek = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
  var passedInDayOfTheWeek = ""

  
  // MARK: - UITableViewDelegate
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    passedInDayOfTheWeek = dayOfTheWeek[indexPath.row]
    NotificationCenter.default.post(name: Notification.Name(rawValue: NotificationCenterConstants.clubsSelectedDayOfWeekChangedKey), object: passedInDayOfTheWeek)
    tableView.reloadData() // Show newly checkmarked day of the week
  }

  
  // MARK: - UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return dayOfTheWeek.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.textLabel?.text = dayOfTheWeek[indexPath.row]
    if dayOfTheWeek[indexPath.row] == passedInDayOfTheWeek { // Mark the currently selected day of the week
      cell.accessoryType = .checkmark
    }
  
    return cell
  }
}
