//
//  SportsTableViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/6/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class SportsTableViewController: UITableViewController {

  @IBOutlet weak var browserTypeSegmentedControl: UISegmentedControl!
  var scheduledGames = [ScheduledSportsGame]()
  var gameResults = [SportsGameResult]()
  var selectedSportName = "Baseball"
  
  /// Used to set the heights for table view cells, add a pull-down-to-refresh control, update the right bar button to show the currently selected sport, add a notification center observer, and download the sports data.
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = tableView.rowHeight
    tableView.rowHeight = UITableViewAutomaticDimension
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshData), for: .valueChanged)
    navigationItem.rightBarButtonItem?.title = selectedSportName
    NotificationCenter.default.addObserver(self, selector: #selector(selectedSportChanged(notification:)), name: NSNotification.Name(rawValue: NotificationCenterConstants.selectedSportChangedKey), object: nil)
    refreshData()
  }
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Used to pass information to the destination view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "sportsToSportsSelection" {
      if let sportsSelectionVC = segue.destination as? SportsSelectionTableViewController {
        sportsSelectionVC.passedSelectedSportName = selectedSportName
      }
    }
  }
  
  /// Called when the segmented control is switched.
  @IBAction func didChangeBrowserType(_ sender: UISegmentedControl) {
    tableView.reloadData()
  }
  
  /// Used to change the selected sport when a new one is selected in the sport selection view controller.
  func selectedSportChanged(notification: NSNotification) {
    if let newSelectedSportName = notification.object as? String {
      selectedSportName = newSelectedSportName
      navigationItem.rightBarButtonItem?.title = newSelectedSportName
      refreshData()
    }
  }
  
  /// Used to download and store schedule/result data for the selected sport.
  func refreshData() {
    refreshScheduledGames()
    refreshGameResults()
  }
  
  /// Used to download, store, and show scheduled games for the selected sport.
  func refreshScheduledGames() {
    SCConnectAPI.REST.Sports.getScheduledGamesForSportWith(name: selectedSportName) { [weak self] (scheduledGames) in
      if scheduledGames != nil {
        self?.scheduledGames = scheduledGames!
      }
      DispatchQueue.main.async { [weak self] in
        if scheduledGames != nil {
          self?.browserTypeSegmentedControl.setTitle("Schedule (\(scheduledGames!.count))", forSegmentAt: 0)
        }
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
      }
    }
  }
  
  /// Used to download, store, and show game result data for the selected sport.
  func refreshGameResults() {
    SCConnectAPI.REST.Sports.getGameResultsForSportWith(name: selectedSportName) { [weak self] (gameResults) in
      if gameResults != nil {
        self?.gameResults = gameResults!.sorted(by: { $0.date > $1.date })
      }
      DispatchQueue.main.async { [weak self] in
        if gameResults != nil {
          self?.browserTypeSegmentedControl.setTitle("Results (\(gameResults!.count))", forSegmentAt: 1)
        }
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
      }
    }
  }
  
  
  // MARK: UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    if browserTypeSegmentedControl.selectedSegmentIndex == 0 && scheduledGames.count <= 0 { // No data message
      let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
      noDataLabel.text = "No scheduled games."
      noDataLabel.numberOfLines = 0 // autolayouts to number of lines needed
      noDataLabel.textColor = UIColor.black
      noDataLabel.textAlignment = .center
      tableView.backgroundView = noDataLabel
      tableView.separatorStyle = .none
      return 0
    } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 && gameResults.count <= 0 {
      let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
      noDataLabel.text = "No game results."
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
      return scheduledGames.count
    } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 {
      return gameResults.count
    }
    
    return 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let sportsCell = tableView.dequeueReusableCell(withIdentifier: "SportsCell") as? SportsTableViewCell { //
      if browserTypeSegmentedControl.selectedSegmentIndex == 0 {
        sportsCell.scheduledGame = scheduledGames[indexPath.row]
        return sportsCell
      } else if browserTypeSegmentedControl.selectedSegmentIndex == 1 {
        sportsCell.gameResult = gameResults[indexPath.row]
        return sportsCell
      }
    }
    
    return UITableViewCell()
  }
}
