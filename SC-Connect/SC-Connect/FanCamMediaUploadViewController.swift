//
//  FanCamMediaUploadViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/23/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import MobileCoreServices //for media type comparison

class FanCamMediaUploadViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  var uploadingMedia = false
  var mediaURL: URL?
  var photoKey: String?
  
  /// Used to show the school property warning if it has not been shown yet.
  override func viewDidLoad() {
    super.viewDidLoad()
    if !UserDefaults.standard.bool(forKey: UserDefaultsConstants.schoolPropertyWarningShownKey) {
      present(UserManager.shared.schoolPropertyWarningAlertController(), animated: true, completion: nil)
      UserDefaults.standard.set(true, forKey: UserDefaultsConstants.schoolPropertyWarningShownKey)
    }
  }
  
  /// Called when the user taps use camera button.
  @IBAction func didChooseCamera(_ sender: Any) {
    let imagePicker = UIImagePickerController()
    imagePicker.delegate = self
    imagePicker.allowsEditing = false
    imagePicker.sourceType = .camera // No media types set bc default is photos only
    present(imagePicker, animated: false, completion: nil)
  }
  
  /// Called when the user taps choose from library button.
  @IBAction func didChooseLibrary(_ sender: Any) {
    let imagePicker = UIImagePickerController()
    imagePicker.delegate = self
    imagePicker.allowsEditing = false
    imagePicker.sourceType = .photoLibrary // No media types set bc default is photos only
    present(imagePicker, animated: false, completion: nil)
  }
  
  /// Called when user taps clear button.
  @IBAction func didTapClear(_ sender: Any) {
    clearMedia()
  }
  
  /// Called when user taps upload button.
  @IBAction func didTapSend(_ sender: Any) {
    guard UserManager.shared.userSignedIn() else {
      Log("User not logged in, so could not upload media message.")
      present(UserManager.shared.notSignedInAlertController(), animated: true, completion: nil)
      return //can't continue unless user signed in
    }
    if !uploadingMedia, let mediaURL = mediaURL, let mediaKey = photoKey {
      uploadingMedia = true
      setRightBarButtonsToLoadingIndicator()
      AWSManager.shared.uploadMediaAt(url: mediaURL, key: mediaKey, completion: { [weak self] in
        SCConnectAPI.REST.FanCam.createFanCamImageRecordWith(awsKey: mediaKey, completion: { [weak self] (success) in
          if success {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.fanCamImageCreatedKey), object: nil)
          }
          self?.uploadingMedia = false
          self?.setRightBarButtonsToUploadAndClear()
          self?.clearMedia()
        })
      })
    } // else nothing selected, so do nothing
  }
  
  /// Used to update right bar buttons to show that the media is being uploaded.
  func setRightBarButtonsToLoadingIndicator() {
    DispatchQueue.main.async { [weak self] in
      let uploadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .gray)
      let activityIndicatorItem = UIBarButtonItem(customView: uploadingIndicatorView)
      uploadingIndicatorView.startAnimating()
      self?.navigationItem.setRightBarButtonItems([activityIndicatorItem], animated: true)
    }
  }
  
  /// Used to update right bar buttons to show that media can now be uploaded.
  func setRightBarButtonsToUploadAndClear() {
    DispatchQueue.main.async { [weak self] in
      if self != nil {
        let clearButtonItem = UIBarButtonItem(title: "Clear", style: .plain, target: self!, action: #selector(self!.didTapClear(_:)))
        let uploadButtonItem = UIBarButtonItem(title: "Upload", style: .plain, target: self!, action: #selector(self!.didTapSend(_:)))
        self?.navigationItem.setRightBarButtonItems([uploadButtonItem, clearButtonItem], animated: true) // Reversed order bc set right to left
      }
    }
  }
  
  /// Used to clear the selected media.
  func clearMedia() {
    if !uploadingMedia {
      mediaURL = nil
      photoKey = nil
      DispatchQueue.main.async { [weak self] in
        self?.imageView.image = nil
      }
    }
  }
}

/// UINavigationControllerDelegate is unused but needed for calling .delegate = self.
extension FanCamMediaUploadViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  /// Used to prepare and show the media that was selected using the image picker controller. This means saving the image locally.
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    AWSManager.shared.getUniqueMediaKey { [weak self] (mediaKey) in
      if let mediaType = info[UIImagePickerControllerMediaType] as? NSString {
        if mediaType == kUTTypeImage && mediaKey != nil, let image = info[UIImagePickerControllerOriginalImage] as? UIImage {
          let fileName = "\(mediaKey!).jpg"
          if let filePath = AWSManager.shared.save(image: image, asJPEGToLocalTempWith: fileName) { //filepath is the url of the saved image
            self?.imageView.image = image
            self?.mediaURL = filePath
            self?.photoKey = fileName
          }
          picker.dismiss(animated: true, completion: nil)
        } else {
          Log("Media type not supported for fan cam upload.")
        }
      }
    }
  }
}
