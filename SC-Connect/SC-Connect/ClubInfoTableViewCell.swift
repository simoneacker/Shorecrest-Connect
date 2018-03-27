//
//  ClubInfoTableViewCell.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/7/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/// Custom table view cell used to display information about a club.
class ClubInfoTableViewCell: UITableViewCell {
  
  /**
      Holds the `Club` model shown in the cell. Passed in by the owner of the cell. Also, updates the cell ui when it is changed.
   
      - Note: Property is used here instead of a function so the full tag info is available if the cell is used as a sender for a segue.
   */
  var club: Club? {
    didSet {
      updateUI()
    }
  }
  
  /// Updates the display to reflect the current club that was passed to the cell.
  private func updateUI() {
    if let club = club {
      textLabel?.text = club.clubName
    }
  }
}
