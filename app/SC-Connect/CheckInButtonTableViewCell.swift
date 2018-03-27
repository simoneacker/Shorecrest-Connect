//
//  CheckInButtonTableViewCell.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 3/30/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/*
    Custom cell for allowing the user to check in.
 
    - Note: Begins in unavailable state.
 */
class CheckInButtonTableViewCell: UITableViewCell {
  
  /// Outlet for the button used to check in/show a lock when unavailable.
  @IBOutlet weak var checkInButton: UIButton!
  
  /// Delegate which allows the cell to notify the controller of user interaction within the cell.
  public var delegate: CheckInButtonTableViewCellDelegate?
  
  /// Used to setup cell to show that the user cannot check in now.
  public func disableCheckIn() {
    checkInButton.setTitle("Check In Unavailable", for: .normal)
    checkInButton.backgroundColor = .gray
    checkInButton.isEnabled = false
  }
  
  /// Used to setup cell to show that the user can check in now.
  public func enableCheckIn() {
    checkInButton.setTitle("Check In To This Event", for: .normal)
    checkInButton.backgroundColor = .blue
    checkInButton.isEnabled = true
  }
  
  /// Used to setup cell to show that the user is checked in.
  public func markAsCheckedIn() {
    checkInButton.setTitle("Checked In", for: .normal)
    checkInButton.backgroundColor = .gray
    checkInButton.isEnabled = false
  }
  
  /// Called when the user taps the check in button to update the delegate.
  @IBAction func didTapCheckIn(_ sender: Any) {
    delegate?.didTapCheckIn()
  }
}

/// Delegate for the `CheckInButtonTableViewCell` to tell its controller of any user interaction within it.
protocol CheckInButtonTableViewCellDelegate {
  
  /// Tells the delegate that the user wants to check in.
  func didTapCheckIn()
}
