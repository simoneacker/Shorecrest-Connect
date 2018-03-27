//
//  SlackPhotoMessageTableViewCell.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 4/22/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/// Custom cell used to display a `PhotoMessage` or `VideoMessage`.
class SlackPhotoMessageTableViewCell: UITableViewCell {

  /// Outlet to a label used to display the name of the user that posted the message.
  @IBOutlet weak var usernameLabel: UILabel!
  
  /// Outlet to a label used to display the date the message was posted.
  @IBOutlet weak var dateLabel: UILabel!
  
  /// Outlet to a image view used to display the photo or video thumbnail of the message.
  @IBOutlet weak var photoImageView: UIImageView!
  
  /// Outlet used to show that the photo is being loaded currently.
  /// - Note: Should start animating from load bc photo has not been set.
  @IBOutlet weak var photoLoadingActivityIndicator: UIActivityIndicatorView!
  
  /// Delegate which allows the cell to notify the controller of user interaction within the cell.
  var delegate: SlackPhotoMessageTableViewDelegate?
  
  /**
      Holds the `SkeletonMessage` model shown in the cell. Passed in by the owner of the cell. Also, updates the cell ui when it is changed.
   
      - Note: Property is used here instead of a function so the full message info is available if the cell is used as a sender for a segue. Ex. SkeletonMessage data passed to delegate method when image view is tapped.
   */
  public var skeletonMessage: SkeletonMessage? {
    didSet {
      updateUI()
    }
  }
  
  /**
      Sets the image view to the passed in photo and start/stop the loading indicator view.
   
      - Parameters:
          - photo: The photo that should be displayed. Optional bc photo could still be loading and the cell should indicate that.
   */
  public func display(photo: UIImage?) {
    if photo != nil {
      photoLoadingActivityIndicator.stopAnimating()
      photoImageView.image = photo
    } else {
      photoLoadingActivityIndicator.startAnimating()
      photoImageView.image = nil
    }
  }
  
  /// Updates the display to reflect the current message that was passed to the cell.
  private func updateUI() {
    if let skeletonMessage = skeletonMessage {
      usernameLabel.text = skeletonMessage.postCreatorName
      dateLabel.text = Helper.stringFrom(date: skeletonMessage.postDate, withFormat: "h:mm a 'on' E, MMM d yyyy")
    }
  }
  
  /// Called when the user taps on the photo. Used to tell the delegate of interaction within the cell.
  @IBAction func didTapPhoto(_ sender: Any) {
    if skeletonMessage != nil {
      delegate?.didTapPhotoInCellOf(message: skeletonMessage!)
    }
  }
}

/// Delegate for the `SlackPhotoMessageTableViewCell` to tell its controller of any user interaction within it.
protocol SlackPhotoMessageTableViewDelegate {
  
  /**
      Tells the delegate that the user tapped on the photo within the cell.
   
      - Parameters:
          - message: The skeleton message of the cell which was tapped. Should contain all information, like a photo or video, needed to show the user further information about the message.
   */
  func didTapPhotoInCellOf(message: SkeletonMessage)
}
