//
//  MessageModel.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 2/6/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation
import UIKit // for images

/** 
    Superclass of all message formats (includes the required variables and initializers to fill those in)
 
    - Note: Using classes instead of structs bc custom messages must conform to superclass type for sake of holding in arrays
    - Note: Subclasses nsobject in case obj-c functions are used on it.
 */
class SkeletonMessage: NSObject {
  
  /// The server's identifier for the message.
  var messageID: Int = -1
  
  /// The name of the tag which the message was posted to.
  var tagName: String = ""
  
  /// The date the message was posted.
  var postDate: Date = Date()
  
  /// The server's id for the poster.
  var postCreatorID: Int = -1
  
  /// The poster's name.
  var postCreatorName: String = ""
  
  
  /**
      Initializes the new message with default values.
   */
  override init() { }
  
  /**
      Initializes the new message with the values from the passed in message.
   
      - Parameters:
          - skeletonMessage: A filled in skeleton message used to fill in this skeleton message.
   */
  init(skeletonMessage: SkeletonMessage) {
    self.messageID = skeletonMessage.messageID
    self.tagName = skeletonMessage.tagName
    self.postDate = skeletonMessage.postDate
    self.postCreatorID = skeletonMessage.postCreatorID
    self.postCreatorName = skeletonMessage.postCreatorName
  }
  
  /**
      Initializes the new message with the passed in values.
     
      - Note: The initializers for the skeleton message superclass are used by subclass initializations in order to fill out the required information. Subclass properties are filled in one by one.
     
      - Parameters:
          - messageID: The server's identifier for the message.
          - tagName: The name of the tag which the message was posted to.
          - postDate: The date that the message was posted on.
          - postCreatorID: The server's id for the user that posted the message.
          - postCreatorName: The name of the user that posted the message.
   */
  init(messageID: Int?, tagName: String, postDate: Date, postCreatorID: Int?, postCreatorName: String) {
    self.messageID = (messageID != nil ? messageID! : -1)
    self.tagName = tagName
    self.postDate = postDate
    self.postCreatorID = (postCreatorID != nil ? postCreatorID! : -1)
    self.postCreatorName = postCreatorName
  }
}


/// Subclass of `SkeletonMessage` class which adds a simple text blurb.
class PureMessage: SkeletonMessage {
  
  /// The text blurb for the message.
  var message: String = ""
}


/// Subclass of `SkeletonMessage` class which adds photo access information and then storage for the image once it has been downloaded.
class PhotoMessage: SkeletonMessage {
  
  /// Unique key used to download the photo from AWS.
  var photoKey: String = ""
  
  /// Used to track whether or not the photo is currently being fetched in order to prevent multiple load attempts of the same photo.
  var loadingPhoto: Bool = false
  
  /// Stores the photo once downloaded to prevent reloading everytime the photo is needed.
  var photo: UIImage?
}


/// Subclass of `SkeletonMessage` class which adds video access information and then storage for the local access information and thumbnail image once it has been downloaded.
class VideoMessage: SkeletonMessage {
  
  /// Unique key used to download the video from AWS.
  var videoKey: String = ""
  
  /// Used to track whether or not the video is currently being fetched in order to prevent multiple load attempts of the same video.
  var loadingVideoURL: Bool = false
  
  /// Stores the local url path of the video once it has been downloaded and saved.
  var videoURL: URL?
  
  /// Stores a thumbnail of the video once it has been created to prevent recreation everytime it is needed.
  var videoThumbnail: UIImage?
}


/// Subclass of `SkeletonMessage` class which adds information about a single upcoming sporting event.
class SportsScheduleMessage: SkeletonMessage {
  
  /// Stores the opponent's name.
  var opponentName: String = ""
  
  /// Stores an abbreviation for the location of the event.
  var location: String = ""
  
  /// Stores a the date of the upcoming event.
  var eventDate: Date = Date()
  
  /// Stores the name of the sport participating in the event.
  var sport: String = ""
}


/// Subclass of `SkeletonMessage` class which adds information about a single completed sporting event.
class SportsResultMessage: SkeletonMessage {
  
  /// Stores the opponent's name.
  var opponentName: String = ""
  
  /// Stores the opponent team's score.
  var opponentScore: Int = -1
  
  /// Stores the home team's score.
  var homeScore: Int = -1 //using home keyword instead of shorecrest in case this code is reused for another school
  
  /// Stores the name of the sport participating in the event.
  var sport: String = ""
}
