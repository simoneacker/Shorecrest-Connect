//
//  EventBrowserViewController.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 3/29/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class EventBrowserViewController: UITableViewController {
  
  @IBOutlet weak var browserTypeSegmentedControl: UISegmentedControl!
  var events = [Event]()
  var leaderboardScores = [LeaderboardScore]()
  
  /// Used to setup the row heights for the table view, a pull-down-to-refresh control, and download event information.
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = tableView.rowHeight
    tableView.rowHeight = UITableViewAutomaticDimension
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    refreshData()
  }
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Used to pass information to the destination view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) { //sender is a tag name string
    if segue.identifier == "eventBrowserToEventInfo" {
      if let eventInfoVC = segue.destination as? EventInfoViewController {
        if let eventInfoCell = sender as? EventInfoTableViewCell {
          eventInfoVC.passedInEvent = eventInfoCell.event ?? Event() //pass selected event or empty event if nil
        }
      }
    }
  }
  
  /// Called when the segmented control is switched.
  @IBAction func didChangeBrowserType(_ sender: UISegmentedControl) {
    refreshData()
  }
  
  /// Called when the totals button is tapped.
  @IBAction func didTapGraduationYearTotals(_ sender: UIBarButtonItem) {
    SCConnectAPI.REST.LeaderboardScores.getLeaderboardPointTotalsForEachGraduationYear { [weak self] (graduationYearTotals) in
      if graduationYearTotals != nil {
        DispatchQueue.main.async { [weak self] in
          let alertController = UIAlertController(title: "Point Totals", message: "", preferredStyle: .alert)
          for i in 0..<graduationYearTotals!.count {
            alertController.message? += "\(graduationYearTotals![i].graduationYear): \(graduationYearTotals![i].totalPoints)"
            if i < graduationYearTotals!.count - 1 {
              alertController.message? += "\n"
            }
          }
          let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
          alertController.addAction(okAction)
          self?.present(alertController, animated: true, completion: nil)
        }
      }
    }
  }
  
  /// Used to download event or leaderboard data and start the ui update.
  func refreshData() {
    if browserTypeSegmentedControl.selectedSegmentIndex == 0 {
      refreshEvents()
    } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 {
      refreshLeaderboard()
    }
  }
  
  /// Used to download all future events and start ui update.
  func refreshEvents() {
    SCConnectAPI.REST.Events.getFutureEvents { [weak self] (events) in
      if events != nil {
        self?.events = events!
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
      }
    }
  }
  
  /// Used to download leaderboard data and start ui update.
  func refreshLeaderboard() {
    SCConnectAPI.REST.LeaderboardScores.getAllLeaderboardScores { [weak self] (leaderboardScores) in
      if leaderboardScores != nil {
        self?.leaderboardScores = leaderboardScores!.sorted(by: { $0.score > $1.score }) //sort into descending order of scores
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
      }
    }
  }
  
  
  // MARK: UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    if browserTypeSegmentedControl.selectedSegmentIndex == 0 && events.count <= 0 { // No data messages
      let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
      noDataLabel.text = "No upcoming events available."
      noDataLabel.numberOfLines = 0 // autolayouts to number of lines needed
      noDataLabel.textColor = UIColor.black
      noDataLabel.textAlignment = .center
      tableView.backgroundView = noDataLabel
      tableView.separatorStyle = .none
      return 0
    } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 && leaderboardScores.count <= 0 {
      let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
      noDataLabel.text = "No leaderboard scores available."
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
      return events.count
    } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 {
      return leaderboardScores.count
    }
    
    return 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if browserTypeSegmentedControl.selectedSegmentIndex == 0, let eventInfoCell = tableView.dequeueReusableCell(withIdentifier: "EventInfoCell") as? EventInfoTableViewCell {
      eventInfoCell.event = events[indexPath.row]
      return eventInfoCell
    } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 {
      let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
      cell.textLabel?.text = "\(indexPath.row + 1). \(leaderboardScores[indexPath.row].username)"
      cell.detailTextLabel?.text = "\(leaderboardScores[indexPath.row].score)"
      return cell
    }
    
    return UITableViewCell()
  }
}
