//
//  EventInfoTableViewCell.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 3/30/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/// Custom cell used to display information about an `Event`.
class EventInfoTableViewCell: UITableViewCell {
  
  /// Displays an icon for the event.
  @IBOutlet weak var eventIconImageView: UIImageView!
  
  /// Shows the name of the event.
  @IBOutlet weak var eventNameLabel: UILabel!
  
  /// Shows information about the location of the event.
  @IBOutlet weak var eventLocationLabel: UILabel!
  
  /// Shows information about the date when check in opens to users.
  @IBOutlet weak var eventCheckInDateLabel: UILabel!
  
  /// Shows the number of the points the event is worth if the user checks in.
  @IBOutlet weak var eventPointsLabel: UILabel!
  
  /*
      Holds the `Event` model shown in the cell. Passed in by the owner of the cell. Also, updates the cell ui when it is changed.
    
      - Note: Property is used here instead of a function so the full event info is available if the cell is used as a sender for a segue.
   */
  public var event: Event? {
    didSet {
      updateUI()
    }
  }
  
  /// Updates the display to reflect the current event that was passed to the cell.
  private func updateUI() {
    if let event = event {
      eventNameLabel.text = event.eventName
      eventLocationLabel.text = "@ \(event.locationName)"
      eventCheckInDateLabel.text = Helper.stringFrom(date: event.startDate, withFormat: "h:mm a 'on' E, MMM d")
      eventPointsLabel.text = "\(event.leaderboardPoints) Points"
    }
  }
}
