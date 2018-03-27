//
//  ClubInfoTableViewController.swift
//  Club_Meetings
//
//  Created by Steven Zhu on 5/20/17.
//  Copyright © 2017 Steven Zhu. All rights reserved.
//

import UIKit

class ClubInfoTableViewController: UITableViewController {
  
  @IBOutlet weak var meetingDaysLabel: UILabel!
  @IBOutlet weak var timeAndLocationLabel: UILabel!
  @IBOutlet weak var leaderNamesLabel: UILabel!
  @IBOutlet weak var tagLabel: UILabel!
  var associatedTag: Tag?
  var passedInClub = Club()

  /// Used to set the navigation title, setup the cells to reflect the passed in club, and download information about the associated tag for passing to slack messages view controller when that segue happens.
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = passedInClub.clubName
    meetingDaysLabel.text = "Meeting Days:  " + passedInClub.meetingDays.joined(separator: ", ")
    timeAndLocationLabel.text = "Meeting Time/Location:  " + passedInClub.meetingTime + " in " + passedInClub.meetingLocation
    leaderNamesLabel.text = "Leaders:  " + passedInClub.clubLeaders.joined(separator: ", ")
    tagLabel.text = "Associated Tag:  " + passedInClub.associatedTagName
    SCConnectAPI.REST.Tags.getInfoForTagWith(name: passedInClub.associatedTagName, completion: { [weak self] (tag) in
      if tag != nil {
        self?.associatedTag = tag
      }
    })
  }
  
  /// Used to pass information to the destination view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "clubInfoToMessages" {
      if let destinationVC = segue.destination as? SlackMessagesViewController {
        if let associatedTag = associatedTag {
          destinationVC.passedTag = associatedTag
        }
      }
    }
  }
}
