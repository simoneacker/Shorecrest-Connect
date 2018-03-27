//
//  SubscriptionsModel.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 2/9/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation
import UIKit // for alert controller creation

/**
    Manages downloading, accessing, and updating tag subscription information.
 
    - Note: All tag name comparisons are lower case because tag names are case insensitive.
 */
class SubscriptionsManager: NSObject {
  
  /// The `Tag` models for each subscribed tag.
  public private(set) var tags = [Tag]()
  
  /// Downloads all of the subscriptions from the server.
  public func configure() {
    downloadSubscriptions()
  }
  
  /// Clears current subscriptions and downloads the user's subscriptions if there is a signed in user.
  public func refreshSubscriptions() {
    clearSubscriptions()
    downloadSubscriptions()
  }
  
  /**
      Add the tag to local stores, updates the server, and sends an internal notifcation of the subscription change. Also joins room for subsribed tags.
   
      - Note: If the user is already subscribed to the given tag, nothing is changed or downloaded.
   
      - Parameters:
          - tagName: The name of tag being subscribed to.
   */
  public func subscribeTo(tagName: String) {
    if tags.index(where: { $0.tagName.lowercased() == tagName.lowercased() }) == nil {
      SCConnectAPI.REST.Subscriptions.subscribeToTagWith(name: tagName, completion: { [weak self] (success) in
        if success {
          self?.downloadDataFor(tagName: tagName, completion: { (success) in
            if success {
              SCConnectAPI.Socket.joinRoomForTagWith(name: tagName)
              MessagesManager.shared.downloadLastMessageForTagWith(name: tagName, completion: nil)
              NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.subscriptionsChangedKey), object: nil)
            }
          })
        }
      })
    }
  }
  
  /**
      Removes the tag from local stores, updates the server, and sends an internal notifcation of the subscription change. Also leaves room for tag.
   
      - Note: If the user is not subscribed to the given tag, nothing is changed or downloaded.
   
      - Parameters:
          - tagName: The name of tag being subscribed to.
   */
  public func unsubscribeFrom(tagName: String) {
    if let indexOfTagToRemove = tags.index(where: { $0.tagName.lowercased() == tagName.lowercased() }) {
      SCConnectAPI.REST.Subscriptions.unsubscribeFromTagWith(name: tagName, completion: { [weak self] (success) in
        if success {
          SCConnectAPI.Socket.leaveRoomForTagWith(name: tagName)
          self?.tags.remove(at: indexOfTagToRemove)
          NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.subscriptionsChangedKey), object: nil)
        }
      })
    }
  }
  
  /** 
      Checks if the user is subscribed to the given tag by name.
   
      - Parameters:
          - tagName: The name of tag being checked for subscription status.
      - Returns: True if user is subscribed to tag name, otherwise false.
   */
  public func isSubscribedTo(tagName: String) -> Bool {
    if tags.index(where: { $0.tagName.lowercased() == tagName.lowercased() }) != nil {
      return true
    }
    
    return false
  }
  
  /**
      Updates the color index of the given tag to the server and in the local `Tag` model copy.
   
      - Note: The user must be signed into a Google Account to call this method.
      - Note: If the user is not subscribed to the given tag, nothing is changed.
   
      - Parameters:
          - tagName: Name of the tag to be updated.
          - colorIndex: The new color index of the tag.
          - completion: Optional completion closure called when the update is complete. Must accept a bool telling whether the update was successful.
   */
  public func updateColorFor(tagName: String, to colorIndex: Int, completion: ((Bool) -> ())?) {
    if let indexOfTagInSubscriptions = tags.index(where: { $0.tagName.lowercased() == tagName.lowercased() }) {
      SCConnectAPI.REST.Tags.updateTagWith(name: tagName, addingNewColorIndex: colorIndex, completion: { [weak self] (success) in
        if success {
          self?.tags[indexOfTagInSubscriptions].colorIndex = colorIndex
        }
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.tagColorChangedKey), object: nil)
        completion?(success)
      })
    } else {
      completion?(false)
    }
  }
  
  /// Downloads the names of all subscribed tags from the server and starts the download of the full `Tag` model for each.
  private func downloadSubscriptions() {
    SCConnectAPI.REST.Subscriptions.getAllSubscribedTagNames { [weak self] (tagNames) in
      if tagNames != nil {
        for tagName in tagNames! {
          self?.downloadDataFor(tagName: tagName, completion: nil)
        }
      }
    }
  }
  
  /// Removes list of subscriptions and sends internal notification that subscriptions have changed.
  private func clearSubscriptions() {
    tags.removeAll()
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.subscriptionsChangedKey), object: nil)
  }
  
  /**
      Downloads the `Tag` model data from the server for the given tag by name.
   
      - Parameters:
          - tagName: The name of tag being requested.
          - completion: The closure called when the tag data download is completed. Used to allow an internal notifications to be posted only after the new tag data is fully available.
   */
  private func downloadDataFor(tagName: String, completion: ((Bool)->())?) {
    SCConnectAPI.REST.Tags.getInfoForTagWith(name: tagName) { [weak self] (tag) in
      if tag != nil {
        self?.tags.append(tag!)
        completion?(true)
      } else {
        completion?(false)
      }
    }
  }
}
