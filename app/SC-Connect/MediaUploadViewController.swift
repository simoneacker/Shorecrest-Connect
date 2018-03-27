//
//  MediaUploadViewController.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 2/19/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import UIKit
import MobileCoreServices //for media type comparison

class MediaUploadViewController: UIViewController {
  
  @IBOutlet weak var imageView: UIImageView!
  var uploadingMedia = false
  var mediaURL: URL?
  var photoKey: String?
  var videoKey: String?
  var passedTag = Tag()
  
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
    if let cameraMediaTypes = UIImagePickerController.availableMediaTypes(for: .camera) {
      imagePicker.sourceType = .camera
      imagePicker.mediaTypes = cameraMediaTypes
      present(imagePicker, animated: false, completion: nil)
    }
  }
  
  /// Called when the user taps choose from library button.
  @IBAction func didChooseLibrary(_ sender: Any) {
    let imagePicker = UIImagePickerController()
    imagePicker.delegate = self
    imagePicker.allowsEditing = false
    if let photoLibraryMediaTypes = UIImagePickerController.availableMediaTypes(for: .photoLibrary) {
      imagePicker.sourceType = .photoLibrary
      imagePicker.mediaTypes = photoLibraryMediaTypes
      present(imagePicker, animated: false, completion: nil)
    }
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
    guard UserManager.shared.isSubscribedTo(tagName: passedTag.tagName) else {
      Log("User not subscribed to the selected tag, so could not upload media message.")
      present(UserManager.shared.notSubscribedAlertController(tagName: passedTag.tagName), animated: true, completion: nil)
      return //can't continue unless subscribed
    }
    if !uploadingMedia, let mediaURL = mediaURL, let mediaKey = photoKey ?? videoKey {
      uploadingMedia = true
      setRightBarButtonsToLoadingIndicator()
      AWSManager.shared.uploadMediaAt(url: mediaURL, key: mediaKey, completion: { [weak self, tagName = passedTag.tagName, photoKey, videoKey] in
        let messageBody = (photoKey != nil ? ["photo_message": ["photo_key": photoKey!]] : ["video_message": ["video_key": videoKey!]]) //already guaranteed that one of the keys exists
        if let messageBodyJSONString = Helper.encodeDictionaryIntoJSONString(dictionary: messageBody) {
          SCConnectAPI.Socket.createMessage(messageBody: messageBodyJSONString, tagName: tagName)
          self?.uploadingMedia = false
          self?.setRightBarButtonsToUploadAndClear()
          self?.clearMedia()
        }
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
      videoKey = nil
      DispatchQueue.main.async { [weak self] in
        self?.imageView.image = nil
      }
    }
  }
}

/// UINavigationControllerDelegate is unused but needed for calling .delegate = self.
extension MediaUploadViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
  /// Used to prepare and show the media that was selected using the image picker controller. This means saving the image locally or generating a thumbnail for a video.
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
        } else if mediaType == kUTTypeMovie && mediaKey != nil, let movieURL = info[UIImagePickerControllerMediaURL] as? URL { //movie url is a temp url in the file system
          if let thumbnailOfVideo = AWSManager.shared.generateThumbnailOfVideoAt(url: movieURL) {
            self?.imageView.image = thumbnailOfVideo
            self?.mediaURL = movieURL
            self?.videoKey = "\(mediaKey!).mov"
          }
          picker.dismiss(animated: true, completion: nil)
        } else {
          Log("Media type not supported for upload.")
        }
      }
    }
  }
}
