//
//  InAppNotificationManager.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/2/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import BRYXBanner

/// Manages listening and posting in-app notifications. Only used for messages.
class InAppNotificationManager: NSObject {
  
  /// Singleton so every part of app stays in sync.
  public static let shared = InAppNotificationManager()
  
  /// Used to start listeners and timers that will send in-app notifications in the future.
  public func configure() {
    notifyOnNewMessages()
  }
  
  /// Listens for new messages and sends an internal notification. Only sends internal notification if the view controller on screen is not a `SlackMessageViewController` with the message's tag open in it.
  public func notifyOnNewMessages() {
    SCConnectAPI.Socket.getNewChatMessage { [weak self] (message) in
      if message != nil, let baseVC = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController, let visibleVC = baseVC.visibleViewController {
        let title = "New message on \(message!.tagName)"
        var notificationMessage = ""
        if let pureMessage = message! as? PureMessage {
          notificationMessage = "\(pureMessage.postCreatorName): \(pureMessage.message)"
        } else if let photoMessage = message! as? PhotoMessage {
          notificationMessage = "\(photoMessage.postCreatorName) posted a photo."
        } else if let videoMessage = message! as? VideoMessage {
          notificationMessage = "\(videoMessage.postCreatorName) posted a video."
        }
        
        if visibleVC.isKind(of: SlackMessagesViewController.self) {
          if (visibleVC as! SlackMessagesViewController).passedTag.tagName != message!.tagName {
            self?.displayInAppNotificationWith(title: title, message: notificationMessage)
          } else {
            // don't send notif
          }
        } else {
          self?.displayInAppNotificationWith(title: title, message: notificationMessage)
        }
      }
    }
  }
  
  /// Uses BRYXBanner to display an in-app notification with the given information. Afterwards, it stores the notification in the local store.
  private func displayInAppNotificationWith(title: String, message: String) {
    DispatchQueue.main.async {
      let bannerColor = UIColor(red: 249.0/255.0, green: 249.0/255.0, blue: 249.0/255.0, alpha: 1.000)
      let banner = Banner(title: title, subtitle: message, image: nil, backgroundColor: bannerColor, didTapBlock: nil)
      banner.textColor = .black
      banner.dismissesOnTap = true
      banner.show(duration: 3.0)
    }
  }
}
