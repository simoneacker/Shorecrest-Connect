//
//  FanCamImageCollectionViewCell.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/23/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/// Custom collection view cell used to display an image on the fan cam page.
class FanCamImageCollectionViewCell: UICollectionViewCell {
  
  /// Outlet to a image view used to display the passed in image.
  @IBOutlet weak var imageView: UIImageView!
  
  /// Outlet used to show that the image is being loaded currently.
  /// - Note: Should start animating from load bc photo has not been set.
  @IBOutlet weak var imageLoadingActivityIndicator: UIActivityIndicatorView!
  
  /**
      Holds the `FanCamImageRecord` shown in the cell. Passed in by the owner of the cell. Also, updates the cell ui when it is changed.
   
      - Note: Property is used here instead of a function so the record is available if the cell is used as a sender for a segue.
   */
  var imageRecord: FanCamImageRecord? {
    didSet {
      updateUI()
    }
  }
  
  /// Updates the cell to show the passed in image or a spinning activity indicator if not set yet.
  func updateUI() {
    if imageRecord != nil {
      imageView.image = imageRecord!.image
      imageLoadingActivityIndicator.stopAnimating()
    } else {
      imageView.image = nil
      imageLoadingActivityIndicator.startAnimating()
    }
  }
}
