//
//  HomepageImageButton.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/31/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/// Custom button used to show text below the image.
class HomepageImageButton: UIButton {
  
  /// Used to set image to aspect fit and center the label.
  override func layoutSubviews() {
    super.layoutSubviews()
    
    titleLabel?.textAlignment = .center
    imageView?.contentMode = .scaleAspectFit
  }
  
  /// Sets title frame to fill whole width on bottom 1/4 of height.
  override func titleRect(forContentRect contentRect: CGRect) -> CGRect {
    
    return CGRect(x: 0.0, y: (contentRect.height / 4.0) * 3.0, width: contentRect.width, height: contentRect.height / 4.0)
  }
  
  /// Sets title frame to fill whole width on top 3/4 of height.
  override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
    
    return CGRect(x: (contentRect.width / 6.0), y: 0.0, width: (contentRect.width / 3.0) * 2.0, height: (contentRect.height / 4.0) * 3.0)
  }
}
