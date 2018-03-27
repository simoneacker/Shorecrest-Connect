//
//  ClubMeetingsTableViewController.swift
//  Club_Meetings
//
//  Created by Steven Zhu on 5/20/17.
//  Copyright © 2017 Steven Zhu. All rights reserved.
//

import UIKit

class ClubMeetingsTableViewController: UITableViewController {
    
  @IBOutlet weak var changeDay: UIBarButtonItem!
  var clubs: [String: [Club]] = ["Monday": [Club](), "Tuesday": [Club](), "Wednesday": [Club](), "Thursday": [Club](), "Friday": [Club]()]
  var selectedDayofTheWeek = "Monday"
  
  /// Used to set the right bar button title to the selected day of week, download all club data, and add a notification center observer.
  override func viewDidLoad() {
    super.viewDidLoad()
    changeDay.title = selectedDayofTheWeek
    SCConnectAPI.REST.Clubs.getAllClubs { [weak self] (clubs) in
      if clubs != nil {
        for club in clubs! {
          for meetingDay in club.meetingDays {
            self?.clubs[meetingDay]?.append(club)
          }
        }
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
      }
    }
    NotificationCenter.default.addObserver(self, selector: #selector(updateSelectedDayOfTheWeek(_:)), name: Notification.Name(rawValue: NotificationCenterConstants.clubsSelectedDayOfWeekChangedKey), object: nil)
  }
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Used to pass information to the destination view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "clubMeetingsToDayOfWeek" {
      if let destinationVC = segue.destination as? DayOfTheWeekSelectionTableViewController {
        destinationVC.passedInDayOfTheWeek = selectedDayofTheWeek
      }
    } else if segue.identifier == "clubMeetingsToClubInfo"{
      if let clubInfoCell = sender as? ClubInfoTableViewCell {
        if let destinationVC = segue.destination as? ClubInfoTableViewController {
          destinationVC.passedInClub = clubInfoCell.club ?? Club()
        }
      }
    }
  }
  
  /// Used to change the selected data of the week when a new one is selected in the day of week selection view controller.
  func updateSelectedDayOfTheWeek(_ notification: Notification) {
    if let newDayOfTheWeek = notification.object as? String {
      selectedDayofTheWeek = newDayOfTheWeek
      DispatchQueue.main.async { [weak self] in
        self?.changeDay.title = newDayOfTheWeek
        self?.tableView.reloadData()
      }
    }
  }
  
  // MARK: - UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    if let clubsOnDay = clubs[selectedDayofTheWeek] { // No data message
      if clubsOnDay.count <= 0 {
        let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: tableView.bounds.size.width, height: tableView.bounds.size.height))
        noDataLabel.text = "No clubs on selected day."
        noDataLabel.numberOfLines = 0 // autolayouts to number of lines needed
        noDataLabel.textColor = UIColor.black
        noDataLabel.textAlignment = .center
        tableView.backgroundView = noDataLabel
        tableView.separatorStyle = .none
        return 0
      }
    }
    
    tableView.backgroundView = nil // Setup to show data
    tableView.separatorStyle = .singleLine
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if let clubsOnDay = clubs[selectedDayofTheWeek] {
      return clubsOnDay.count
    }
    
    return 0
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let clubInfoCell = tableView.dequeueReusableCell(withIdentifier: "ClubInfoCell") as? ClubInfoTableViewCell {
      if let clubsOnDay = clubs[selectedDayofTheWeek] {
        clubInfoCell.club = clubsOnDay[indexPath.row]
        return clubInfoCell
      }
    }
  
    return UITableViewCell()
  }
}
