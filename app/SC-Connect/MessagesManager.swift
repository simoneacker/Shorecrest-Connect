//
//  MessagesManager.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/1/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/** 
    Manages temporarily storing/accessing last messages on tags and permanent storage/access to last read message ids.
 
    - Note: Uses REST API to download the last message.
 */
class MessagesManager: NSObject {

  /// Singleton so every part of app stays in sync.
  public static let shared = MessagesManager()
  
  /// Stores the last message for a tag (by name) once it has been downloaded. Public GET only but local GET/SET.
  public private(set) var lastMessages = [String: SkeletonMessage]()
  
  /// Stores the last read message ids for tags (by name) once any message has been read. Public GET only but local GET/SET.
  public private(set) var lastReadMessageIDs = [String: Int]()
  
  /// Used to store the new last message and send an internal notification of the new message.
  public func configure() {
    loadLastReadMessageIdentifiers()
    SCConnectAPI.Socket.getNewChatMessage { [weak self] (message) in
      if message != nil {
        self?.lastMessages[message!.tagName] = message!
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.newMessagePostedKey), object: nil)
      }
    }
  }
  
  /// Loads the last read message identifiers from User Defaults
  func loadLastReadMessageIdentifiers() {
    if let lastReadMessageIdentifiersFromDefaults = UserDefaults.standard.dictionary(forKey: UserDefaultsConstants.lastReadMessageIdentifiersKey) as? [String: Int] {
      lastReadMessageIDs = lastReadMessageIdentifiersFromDefaults
      Log("Successfully loaded last read message identifiers from UserDefaults.")
    } else {
      Log("Failed to load last read message identifiers from UserDefaults. No value for key or wrong type of dictionary.")
    }
  }
  
  /// Saves the last read message identifiers to User Defaults
  func saveLastReadMessageIdentifiers() {
    UserDefaults.standard.set(lastReadMessageIDs, forKey: UserDefaultsConstants.lastReadMessageIdentifiersKey)
    Log("Successfully saved last read message identifiers to UserDefaults.")
  }
  
  /**
      Updates the last read message identifier of the given tag (by name) and saves all last read message identifiers.
   
      - Parameters:
          - tagName: The name of the tag to update.
          - messageID: The new last read messageID.
   */
  func updateLastReadMessageIndentifierFor(tagName: String, to messageID: Int) {
    let lastReadMessageIDForTag = lastReadMessageIDs[tagName] ?? 0 // Defaults to 0 bc works to say no read
    if messageID > lastReadMessageIDForTag {
      lastReadMessageIDs[tagName] = messageID
      NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.lastReadMessagesChangedKey), object: nil)
      saveLastReadMessageIdentifiers()
    }
  }
  
  /// Downloads the last message for every subscribed tag.
  public func downloadLastMessagesForAllSubscriptions() {
    for tag in UserManager.shared.getSubscribedTags() {
      downloadLastMessageForTagWith(name: tag.tagName, completion: nil)
    }
  }
  
  /**
      Downloads and stores the last message for the given tag to the lastMessages dictionary. Also sets last read message id since no messages have been read. Offers an optional completion to let the caller track when the download completes.
   
      - Note: Only downloads the message if is isn't in the lastMessages dictionary.
   
      - Parameters:
          - tagName: The name of the tag to download the last message for.
          - completion: The optional closure called when the messages has been downloaded.
   */
  public func downloadLastMessageForTagWith(name tagName: String, completion: (() -> ())?) {
    if lastMessages[tagName] == nil {
      SCConnectAPI.REST.Messages.lastMessageFromTagWith(name: tagName) { [weak self] (message) in
        if message != nil {
          self?.lastMessages[tagName] = message!
        } else {
          let errorMessage = PureMessage(messageID: nil, tagName: tagName, postDate: Date(), postCreatorID: nil, postCreatorName: "Bot") //"Bot" is the user for the error message
          errorMessage.message = "No messages yet."
          self?.lastMessages[tagName] = errorMessage
        }
        if self?.lastReadMessageIDs[tagName] == nil {
          self?.lastReadMessageIDs[tagName] = 0
        }
        completion?()
      }
    } else {
      completion?()
    }
  }
}
