//
//  FanCamImage.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/23/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/// Model for holding data about an image uploaded to fan cam.
struct FanCamImageRecord {
  
  /// Stores the server's id for the fan cam image record.
  var recordID: Int = -1
  
  /// Stores the unique key of the image on the AWS S3.
  var imageAWSKey: String = ""
  
  /// Stores the image once it has been downloaded.
  var image: UIImage?
}
