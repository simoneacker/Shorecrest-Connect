//
//  FanCamCollectionViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/23/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class FanCamCollectionViewController: UICollectionViewController {

  var fanCamImageRecords = [FanCamImageRecord]()
  
  /// Used to download the fan cam records and add a notification center observer.
  override func viewDidLoad() {
    super.viewDidLoad()
    refreshFanCamImages()
    NotificationCenter.default.addObserver(self, selector: #selector(refreshFanCamImages), name: NSNotification.Name(rawValue: NotificationCenterConstants.fanCamImageCreatedKey), object: nil)
  }
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Used to pass information to the destination view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "fanCamToPhotoDisplay" {
      if let photoDisplayVC = segue.destination as? PhotoDisplayViewController {
        if let fanCamImageCell = sender as? FanCamImageCollectionViewCell {
          photoDisplayVC.passedPhoto = fanCamImageCell.imageRecord?.image
        }
      }
    }
  }
  
  /// Used to handle a long press gesture on a collection view cell.
  func didLongPressCell(_ gesture: UIGestureRecognizer) {
    if gesture.state != .began, let gestureView = gesture.view {
      let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
      alertController.modalPresentationStyle = .popover
      alertController.popoverPresentationController?.sourceView = gestureView.superview
      alertController.popoverPresentationController?.sourceRect = gestureView.frame
      if UserManager.shared.userSignedIn() && UserManager.shared.getUser()!.isModerator {
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (action) -> Void in
          let fanCamRecordID = (gestureView as? FanCamImageCollectionViewCell)?.imageRecord?.recordID
          if fanCamRecordID != nil {
            SCConnectAPI.REST.Moderators.hideFanCamImageRecordBy(id: fanCamRecordID!, completion: { [weak self] (success) in
              if success {
                let alertController = UIAlertController(title: "Deleted Successfully", message: "The fan cam image was permanently deleted.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                DispatchQueue.main.async { [weak self] in
                  self?.present(alertController, animated: true, completion: nil)
                }
              }
            })
            if self != nil {
              for i in 0..<self!.fanCamImageRecords.count {
                if self!.fanCamImageRecords[i].recordID == fanCamRecordID! {
                  self?.fanCamImageRecords.remove(at: i)
                  DispatchQueue.main.async { [weak self] in
                    self?.collectionView?.reloadData()
                  }
                  break
                }
              }
            }
          }
        }))
      }
      alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
      navigationController?.present(alertController, animated: true, completion: nil)
    }
  }
  
  /// Updates the data and starts a ui update to show the most current fan cam images.
  func refreshFanCamImages() {
    SCConnectAPI.REST.FanCam.getFanCamImageRecords { [weak self] (fanCamImages) in
      if fanCamImages != nil {
        self?.fanCamImageRecords = fanCamImages!.reversed() //bc newest last
      }
      DispatchQueue.main.async { [weak self] in
        self?.collectionView?.reloadData()
      }
    }
  }

  // MARK: UICollectionViewDataSource

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    if fanCamImageRecords.count <= 0 { // No data message
      let noDataLabel = UILabel(frame: CGRect(x: 0, y: 0, width: collectionView.bounds.size.width, height: collectionView.bounds.size.height))
      noDataLabel.text = "No photos."
      noDataLabel.numberOfLines = 0 // autolayouts to number of lines needed
      noDataLabel.textColor = UIColor.black
      noDataLabel.textAlignment = .center
      collectionView.backgroundView = noDataLabel
      return 0
    }
    
    collectionView.backgroundView = nil // Setup to show data
    return 1
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return fanCamImageRecords.count
  }

  override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    if let imageCell = collectionView.dequeueReusableCell(withReuseIdentifier: "FanCamImageCell", for: indexPath) as? FanCamImageCollectionViewCell {
      if imageCell.gestureRecognizers?.count == nil {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell(_:)))
        imageCell.addGestureRecognizer(longPress)
      }
      if fanCamImageRecords[indexPath.row].image != nil {
        imageCell.imageRecord = fanCamImageRecords[indexPath.row]
      } else {
        imageCell.imageRecord = nil
        AWSManager.shared.downloadImageWith(key: fanCamImageRecords[indexPath.row].imageAWSKey, completion: { [weak self] (image) in
          self?.fanCamImageRecords[indexPath.row].image = image ?? UIImage(named: "error_image")
          DispatchQueue.main.async { [weak self] in
            self?.collectionView?.reloadItems(at: [indexPath])
          }
        })
      }
      return imageCell
    }
    
    return UICollectionViewCell()
  }
}
