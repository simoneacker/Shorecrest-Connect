//
//  SCConnectSocketAPI.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/2/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/**
    The Socket Application Program Interface (API) between the SC-Connect iOS App and backend server.
 
    - Note: All functions are static so they can be called without initializing a `SCConnectSocketAPI` object.
    - Note: Uses shared instance of `SocketIOManager`.
    - Note: No log messages when emit point reached because all emits have acks that log whether or not they were successful.
 */
struct SCConnectSocketAPI {
  
  /**
      Socket Emitters
   */
  
  /// User posted a message.
  public static func createMessage(messageBody: String, tagName: String) {
    if messageBody.characters.count <= 512 && tagName.characters.count <= 8 {
      if let token = UserManager.shared.getAuthenticationInfo() {
        SocketIOManager.shared.emit(eventName: "createMessage", data: ["auth_token": token.encodedString, "message_body": messageBody, "tag_name": tagName], completion: nil)
      } else if UserManager.shared.userSignedIn() {
        UserManager.shared.refreshAuthenticationInfo()
        Log("Failed to create message. Authentication info expired. Authentication info refresh started.")
      } else {
        Log("Failed to create message. Authentication info invalid.")
      }
    } else {
      Log("Failed to create message. Message body or tag name was too long.")
    }
  }
  
  /// User started typing message.
  public static func sendStartTypingMessageOnTagWith(name tagName: String) {
    if tagName.characters.count <= 8 {
      if let token = UserManager.shared.getAuthenticationInfo() {
        SocketIOManager.shared.emit(eventName: "startTyping", data: ["auth_token": token.encodedString, "tag_name": tagName], completion: nil)
      } else if UserManager.shared.userSignedIn() {
        UserManager.shared.refreshAuthenticationInfo()
        Log("Failed to send start typing update. Authentication info expired. Authentication info refresh started.")
      } else {
        Log("Failed to send start typing update. Authentication info invalid.")
      }
    } else {
      Log("Failed to send start typing update. Tag name was too long.")
    }
  }
  
  /// User stopped typing message.
  public static func sendStopTypingMessageOnTagWith(name tagName: String) {
    if tagName.characters.count <= 8 {
      if let token = UserManager.shared.getAuthenticationInfo() {
        SocketIOManager.shared.emit(eventName: "stopTyping", data: ["auth_token": token.encodedString, "tag_name": tagName], completion: nil)
      } else if UserManager.shared.userSignedIn() {
        UserManager.shared.refreshAuthenticationInfo()
        Log("Failed to send stop typing update. Authentication info expired. Authentication info refresh started.")
      } else {
        Log("Failed to send stop typing update. Authentication info invalid.")
      }
    } else {
      Log("Failed to send stop typing update. Tag name was too long.")
    }
  }
  
  /// Join all subscribed rooms.
  public static func joinAllSubscribedRooms() {
    if let token = UserManager.shared.getAuthenticationInfo() {
      SocketIOManager.shared.emit(eventName: "joinAllSubscribedRooms", data: ["auth_token": token.encodedString], completion: nil)
    } else if UserManager.shared.userSignedIn() {
      UserManager.shared.refreshAuthenticationInfo()
      Log("Failed to join all subscribed rooms. Authentication info expired. Authentication info refresh started.")
    } else {
      Log("Failed to join all subscribed rooms. Authentication info invalid.")
    }
  }
  
  /// Join just one room.
  public static func joinRoomForTagWith(name tagName: String) {
    if tagName.characters.count <= 8 {
      if let token = UserManager.shared.getAuthenticationInfo() {
        SocketIOManager.shared.emit(eventName: "joinRoom", data: ["auth_token": token.encodedString, "tag_name": tagName], completion: nil)
      } else if UserManager.shared.userSignedIn() {
        UserManager.shared.refreshAuthenticationInfo()
        Log("Failed to join room for tag (\(tagName)). Authentication info expired. Authentication info refresh started.")
      } else {
        Log("Failed to join room for tag (\(tagName)). Authentication info invalid.")
      }
    } else {
      Log("Failed to join room for tag (\(tagName)). Tag name was too long.")
    }
  }
  
  /// Leave one room.
  public static func leaveRoomForTagWith(name tagName: String) {
    if tagName.characters.count <= 8 {
      if let token = UserManager.shared.getAuthenticationInfo() {
        SocketIOManager.shared.emit(eventName: "leaveRoom", data: ["auth_token": token.encodedString, "tag_name": tagName], completion: nil)
      } else if UserManager.shared.userSignedIn() {
        UserManager.shared.refreshAuthenticationInfo()
        Log("Failed to leave room for tag (\(tagName)). Authentication info expired. Authentication info refresh started.")
      } else {
        Log("Failed to leave room for tag (\(tagName)). Authentication info invalid.")
      }
    } else {
      Log("Failed to leave room for tag (\(tagName)). Tag name was too long.")
    }
  }
  
  /**
      Socket Listeners
   */
  
  /// Listens for new chat messages. Should only receive messages from tags that the user is subscribed to.
  public static func getNewChatMessage(completion: @escaping (SkeletonMessage?) -> ()) {
    SocketIOManager.shared.on(eventName: "newMessage") { (dataArray, socketAck) in
      if dataArray.count == 1, let messageDictionary = dataArray[0] as? NSDictionary {
        let messageModelsParsedFromDictionary = SCConnectAPI.REST.Messages.parseMessageModelsFrom(messageDictionaries: [messageDictionary])
        if messageModelsParsedFromDictionary.count == 1 {
          Log("Successfully grabbed and parsed the newest message on tag (\(messageModelsParsedFromDictionary[0].tagName)).")
          completion(messageModelsParsedFromDictionary[0])
        } else {
          Log("Failed to get newest message. More than one filled in message returned.")
          completion(nil)
        }
      } else {
        Log("Failed to get newest message. Invalid message data sent.")
        completion(nil)
      }
    }
  }
  
  /// Listens for typing updates on tags that the user is subscribed to.
  public static func getTypingUpdate(completion: @escaping (String?, [String]?) -> ()) {
    SocketIOManager.shared.on(eventName: "typingUpdate") { (dataArray, socketAck) in
      if dataArray.count == 2, let tagName = dataArray[0] as? String, let typingUsernameList = dataArray[1] as? [String] {
        Log("Successfully grabbed list of users that are currently typing.")
        completion(tagName, typingUsernameList)
      } else {
        Log("Failed to get list of users that are currently typing. Invalid info returned.")
        completion(nil, nil)
      }
    }
  }
  
  
}
