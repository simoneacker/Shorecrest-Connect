//
//  PhotoDisplayViewController.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 2/22/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import UIKit

/// A full screen image view for inspecting an photo from a message.
class PhotoDisplayViewController: UIViewController {
  
  @IBOutlet weak var photoZoomScrollView: UIScrollView!
  var photoImageView = UIImageView() // Image view is not an outlet bc it is added as a subview of the scroll view to allow zooming.
  var passedPhoto: UIImage?
  
  /// Used to display the passed in photo and setup the scroll view for zooming.
  override func viewDidLoad() {
    super.viewDidLoad()
    automaticallyAdjustsScrollViewInsets = false
    photoImageView.image = passedPhoto
    photoImageView.contentMode = .scaleAspectFit
    photoZoomScrollView.delegate = self
    photoZoomScrollView.addSubview(photoImageView)
  }
  
  /// Alters the content size as autolayout takes affect and the nav bar is hidden/shown.
  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    let contentSize = photoZoomScrollView.bounds.size
    photoImageView.frame = CGRect(origin: CGPoint.zero, size: contentSize)
    photoZoomScrollView.contentSize = contentSize
  }
  
  /// Used to turn on hide nav bar on tap feature.
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.hidesBarsOnTap = true
  }
  
  /// Used to turn off hide nav bar on tap feature so it doesn't affect other views.
  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.hidesBarsOnTap = false
  }
}

extension PhotoDisplayViewController: UIScrollViewDelegate {
  
  /// Used to provide the view that will be zoomed in or out.
  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return photoImageView
  }
}
