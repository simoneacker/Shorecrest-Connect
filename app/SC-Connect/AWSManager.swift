//
//  AWSManager.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 2/14/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation
import AWSCore
import AWSS3
import AVFoundation //for video thumbnail generation

/**
    Manages upload and download of media from Amazon Web Services (AWS).
 
    - Note: Media is stored using AWS S3.
 */
class AWSManager: NSObject {
  
  /// Singleton of `AWSManager` class. Used so there is just one instance which is properly configured to upload and download media.
  public static let shared = AWSManager()
  
  /// Configures the AWS S3 libraries needed for upload and download.
  public func configure() {
    let credentialProvider = AWSCognitoCredentialsProvider(regionType: AWSConstants.region, identityPoolId: AWSConstants.poolID)
    let configuration = AWSServiceConfiguration(region: AWSConstants.region, credentialsProvider: credentialProvider)
    AWSServiceManager.default().defaultServiceConfiguration = configuration
  }
  
  /**
      Downloads the requested image, temporarily stores it locally, and then loads the image from the local store to pass back to the sender.
   
      - Parameters:
          - key: The unique identifier for the requested image.
          - completion: The handler called when the download request is completed. Needs to accept an optional image.
   */
  public func downloadImageWith(key: String, completion: @escaping (UIImage?) -> ()) {
    if let downloadRequest = AWSS3TransferManagerDownloadRequest() {
      downloadRequest.bucket = AWSConstants.bucketName
      downloadRequest.key = key
      downloadRequest.downloadingFileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(key)) // Local temp where image will be saved
      AWSS3TransferManager.default().download(downloadRequest).continueWith(executor: AWSExecutor.mainThread()) { (task:AWSTask<AnyObject>) -> Any? in
        if let error = task.error as NSError? {
          DebugLog("Error downloading image: \(downloadRequest.key.debugDescription) Error: \(error)")
          completion(nil)
        } else {
          let imageFromTempFile = UIImage(contentsOfFile: downloadRequest.downloadingFileURL.path)
          DebugLog("Download complete for image: \(downloadRequest.key.debugDescription)")
          completion(imageFromTempFile)
        }
        
        return nil // Return is for AWS completion handler
      }
    } else {
      DebugLog("Error downloading image. Could not create download request object.")
      completion(nil)
    }
  }
  
  /**
      Downloads the requested video, temporarily stores it locally, and then passes back the path of the local store to the sender.
     
      - Note: URL passed back instead of video file because apple's video player takes a URL not a video file.
   
      - Parameters:
          - key: The unique identifier for the requested video.
          - completion: The handler called when the download request is completed. Needs to accept an optional url.
   */
  public func downloadVideoWith(key: String, completion: @escaping (URL?) -> ()) {
    if let downloadRequest = AWSS3TransferManagerDownloadRequest() {
      downloadRequest.bucket = AWSConstants.bucketName
      downloadRequest.key = key
      downloadRequest.downloadingFileURL = URL(fileURLWithPath: NSTemporaryDirectory().appending(key)) // Local temp where video will be saved
      AWSS3TransferManager.default().download(downloadRequest).continueWith(executor: AWSExecutor.mainThread()) { (task:AWSTask<AnyObject>) -> Any? in
        if let error = task.error as NSError? {
          DebugLog("Error downloading video: \(downloadRequest.key.debugDescription) Error: \(error)")
          completion(nil)
        } else {
          DebugLog("Download complete for video: \(downloadRequest.key.debugDescription)")
          completion(downloadRequest.downloadingFileURL)
        }
        
        return nil // Return is for AWS completion handler
      }
    } else {
      DebugLog("Error downloading video. Could not create download request object.")
      completion(nil)
    }
  }
  
  /**
      Uploads the media at the given local url with the given unique key.
   
      - Note: The key passed to this function must be unique, so it should have been verified that no other media with that key exists.
   
      - Parameters:
          - key: Local path to the media file.
          - key: The unique identifier for the media file.
          - completion: The handler called when the upload request is completed. Optional because completion does not send any data back, it just notifies that upload is complete.
   */
  public func uploadMediaAt(url: URL, key: String, completion: (() -> ())?) {
    if let uploadRequest = AWSS3TransferManagerUploadRequest() {
      uploadRequest.bucket = AWSConstants.bucketName
      uploadRequest.key = key
      uploadRequest.body = url
      AWSS3TransferManager.default().upload(uploadRequest).continueWith(executor: AWSExecutor.mainThread(), block: { (task) -> Any? in
        if let error = task.error as NSError? {
          DebugLog("Error uploading: \(uploadRequest.key.debugDescription) Error: \(error)")
          completion?()
        } else {
          DebugLog("Upload complete for: \(uploadRequest.key.debugDescription)")
          completion?()
        }
        
        return nil // Return is for AWS completion handler
      })
    } else {
      DebugLog("Error uploading media. Could not create upload request object.")
      completion?()
    }
  }
  
  /**
      Generates a thumbnail image for the video at the given local path and then layers a play icon on top to make it obvious that the image is a thumbnail.
   
      - Note: The thumbnail is taken at 1 second into the video. This is only an issue if the video is less than a second long, at which case, no thumbnail will be generated.
   
      - Parameters:
          - url: The local path to the video file.
   
      - Returns: An image if a thumbnail was generated or nil if something went wrong.
   */
  public func generateThumbnailOfVideoAt(url: URL) -> UIImage? {
    do {
      let asset = AVAsset(url: url)
      let assetImageGenerator = AVAssetImageGenerator(asset: asset)
      assetImageGenerator.appliesPreferredTrackTransform = true //keeps a portrait video from camera upright in the thumbnail
      
      let time = CMTimeMakeWithSeconds(Float64(1), 100) //image at second 1 on a timescale of 100
      let cgImage = try assetImageGenerator.copyCGImage(at: time, actualTime: nil) //core graphics image from video
      let thumbnail = UIImage(cgImage: cgImage)
      
      if let playIcon = UIImage(named: "play_icon") {
        if thumbnail.size.width > playIcon.size.width && thumbnail.size.height > playIcon.size.height { // Check that the play icon is smaller than the video, otherwise issue.
          
          // Configure the layout of the play icon so it is centered on top of the thumbnail image
          let combinedImageSize = thumbnail.size
          let combinedImageRect = CGRect(x: 0, y: 0, width: combinedImageSize.width, height: combinedImageSize.height)
          let xValueOfPlayIcon = (combinedImageRect.width / 2.0) - (playIcon.size.width / 2.0)
          let yValueOfPlayIcon = (combinedImageRect.height / 2.0) - (playIcon.size.height / 2.0)
          let playIconRect = CGRect(x: xValueOfPlayIcon, y: yValueOfPlayIcon, width: playIcon.size.width, height: playIcon.size.height)
          
          // Combine the play icon on top of the video thumbnail
          UIGraphicsBeginImageContext(combinedImageSize)
          thumbnail.draw(in: combinedImageRect)
          playIcon.draw(in: playIconRect)
          let combinedImage = UIGraphicsGetImageFromCurrentImageContext()
          UIGraphicsEndImageContext()
          DebugLog("Successfully generated thumbnail for video at url (\(url)).")
          
          return combinedImage
        }
      }
    } catch let error {
      DebugLog("Error generating thumbnail for video at url (\(url)): \(error)")
    }
    
    return nil
  }
  
  /**
      Saves the image to a temporary local file and passes back the path to the local file.
   
      - Parameters:
          - image: The image to be stored in a temporary local file.
          - fileName: The name of the image with a jpg or jpeg ending.
   
      - Returns: The url if the image was saved properly or nil if something went wrong.
   */
  public func save(image: UIImage, asJPEGToLocalTempWith fileName: String) -> URL? {
    if let jpegDataFromImage = UIImageJPEGRepresentation(image, 1.0) {
      do {
        let filePath = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)
        try jpegDataFromImage.write(to: filePath)
        DebugLog("Successfully saved selected image to file at path (\(filePath)).")
        
        return filePath
      } catch let error {
        DebugLog("Error saving selected image to file: \(error)")
      }
    } else {
      DebugLog("Error saving selected image to file. Could not create data from UIImage.")
    }
    
    return nil
  }
  
  /** 
      Generates a unique key and then checks if it already exists. It repeats this recursively until it generates a completely unique key.
   
      - Note: The key existence check is done by requesting a head object (just the header information, not body) for the unique key. If the head object is sent back, then the key is not unique, and another is generated.
      - Note: This method returns 40 character alphanumeric keys. There are 52^40 possibilities, so there should rarely be collisions with existing keys.
   
      - Parameters:
          - completion: The handler called when a unique key has been found. Needs to accept an optional string in case something goes wrong.
   */
  public func getUniqueMediaKey(completion: @escaping (String?) -> ()) {
    let generatedKey = Helper.randomAlphaNumericString(length: 40)
    if let headObjectRequest = AWSS3HeadObjectRequest() {
      headObjectRequest.bucket = AWSConstants.bucketName
      headObjectRequest.key = generatedKey
      AWSS3.default().headObject(headObjectRequest).continueWith(executor: AWSExecutor.mainThread(), block: { [weak self] (task) -> Any? in
        if task.error as NSError? != nil { // Error means nothing found, so the key is unique
          DebugLog("Generated unique media key (\(generatedKey)).")
          completion(generatedKey)
        } else {
          self?.getUniqueMediaKey(completion: { (newKey) in // Recursively get new key until one is unique
            completion(newKey)
          })
        }
        
        return nil // Return is for AWS completion handler
      })
    } else {
      DebugLog("Failed to generate unique media key. Could not create head request object.")
      completion(nil)
    }
  }
}
