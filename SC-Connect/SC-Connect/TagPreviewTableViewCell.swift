//
//  TagPreviewTableViewCell.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 3/9/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import UIKit

/// Custom cell used to show tag information and the most recent message in order to give the user a preview of that tag.
class TagPreviewTableViewCell: UITableViewCell {

  /// Displays a tag icon colored with the tag's selected color.
  @IBOutlet weak var tagIconImageView: UIImageView!
  
  /// Shows the tag name.
  @IBOutlet weak var tagNameLabel: UILabel!
  
  /// Shows the time of the last message.
  @IBOutlet weak var timeLabel: UILabel!
  
  /// Shows the text of the last message or a blurb about it being a photo/video.
  @IBOutlet weak var lastMessageLabel: UILabel!
  
  /// Shown if unread messages available, otherwise hidden.
  /// Sets layer properties to make view circular once outlet is set.
  @IBOutlet weak var unreadMessagesIndicatorView: UIView! {
    didSet {
      unreadMessagesIndicatorView.layer.cornerRadius = 7.5
    }
  }
  
  /**
      Holds the `Tag` model shown in the cell. Passed in by the owner of the cell. Also, updates the cell ui when it is changed.
   
      - Note: Property is used here instead of a function so the full tag info is available if the cell is used as a sender for a segue.
   */
  public var previewTag: Tag? {
    didSet {
      updateUI()
    }
  }
  
  /**
      Sets the last message and the unread indicator displayed in the cell.
   
      - Parameters:
          - message: The mesage to be displayed in the cell. Optional so "Loading..." if the last message hasn't been downloaded yet.
          - isUnread: A bool tracking if the last message is unread. Used to update the unread indicator.
   */
  public func displayLast(message: SkeletonMessage?, unread isUnread: Bool) {
    if let message = message {
      timeLabel.text = Helper.stringFrom(date: message.postDate, withFormat: "h:mm a 'on' E, MMM d")
      
      if isUnread {
        unreadMessagesIndicatorView.isHidden = false
      } else {
        unreadMessagesIndicatorView.isHidden = true
      }
      
      if let pureMessage = message as? PureMessage {
        lastMessageLabel.text = "\(pureMessage.postCreatorName): \(pureMessage.message)"
      } else if let photoMessage = message as? PhotoMessage {
        lastMessageLabel.text = "\(photoMessage.postCreatorName) posted a photo."
      } else if let videoMessage = message as? VideoMessage {
        lastMessageLabel.text = "\(videoMessage.postCreatorName) posted a video."
      }
    } else {
      unreadMessagesIndicatorView.isHidden = true
      timeLabel.text = "Loading..."
      lastMessageLabel.text = "Loading..."
    }
  }
  
  /// Updates the display to reflect the current tag that was passed to the cell.
  private func updateUI() {
    if let tag = previewTag {
      tagNameLabel.text = tag.tagName
      tagIconImageView.image = UIImage(named: "tag_icon")?.withRenderingMode(.alwaysTemplate) //removes color from the tag icon image so tint color is portrayed
      tagIconImageView.tintColor = TagConstants.colorFor(index: tag.colorIndex)
      unreadMessagesIndicatorView.isHidden = true // hidden unless messages available
    }
  }
  
}
