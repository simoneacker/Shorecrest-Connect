//
//  SportsSelectionTableViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/6/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class SportsSelectionTableViewController: UITableViewController {
  
  let sportNames = ["Baseball", "B-Basketball", "Football", "B-Golf", "B-Soccer", "B-Swim", "B-Tennis", "B-Track", "Wrestling", "B-X-Country", "G-Basketball", "G-Golf", "Gymnastics", "G-Soccer", "Softball", "G-Swim", "G-Tennis", "G-Track", "Volleyball", "G-X-Country"]
  var passedSelectedSportName = ""
  
  
  // MARK: UITableViewDelegate
  
  override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    passedSelectedSportName = sportNames[indexPath.row]
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.selectedSportChangedKey), object: sportNames[indexPath.row])
    tableView.reloadData() //show new checkmarked item
  }
  
  
  // MARK: UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return sportNames.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = UITableViewCell(style: .default, reuseIdentifier: nil)
    cell.textLabel?.text = sportNames[indexPath.row]
    if sportNames[indexPath.row] == passedSelectedSportName { //mark the currently selected sport
      cell.accessoryType = .checkmark
    }
    return cell
  }
}
