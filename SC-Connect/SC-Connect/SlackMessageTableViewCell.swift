//
//  SlackMessageTableViewCell.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 4/22/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/// Custom cell used to display a `PureMessage`.
class SlackMessageTableViewCell: UITableViewCell {
  
  /// Outlet to a label used to display the name of the user that posted the message.
  @IBOutlet weak var usernameLabel: UILabel!
  
  /// Outlet to a label used to display the date the message was posted.
  @IBOutlet weak var dateLabel: UILabel!
  
  /// Outlet to a label used to display the text of the message.
  @IBOutlet weak var messageLabel: UILabel!
  
  /*
      Holds the `PureMessage` model shown in the cell. Passed in by the owner of the cell. Also, updates the cell ui when it is changed.
   
      - Note: Property is used here instead of a function so the full message info is available if the cell is used as a sender for a segue.
      - Note: `PureMessage` instead of `SkeletonMessage` because the message must have a text body.
   */
  public var pureMessage: PureMessage? {
    didSet {
      updateUI()
    }
  }
  
  /// Updates the display to reflect the current message that was passed to the cell.
  private func updateUI() {
    if let pureMessage = pureMessage {
      usernameLabel.text = pureMessage.postCreatorName
      dateLabel.text = Helper.stringFrom(date: pureMessage.postDate, withFormat: "h:mm a 'on' E, MMM d yyyy")
      messageLabel.text = pureMessage.message
    }
  }
}

//messageTextView.textContainerInset = UIEdgeInsets.zero //remove top and bottom padding around text
//messageTextView.textContainer.lineFragmentPadding = 0 //remove left and right padding by removing padding on the NSTextContainer (which holds the text)
