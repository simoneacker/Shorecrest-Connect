//
//  AppDelegate.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 1/19/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import UIKit
import UserNotifications
import GoogleSignIn //for url handling

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

  var window: UIWindow?

  /// Used to initialize and configure many app features.
  func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
    
    // Prepare all of the managers and models needed for the app to work.
    AWSManager.shared.configure()
    UserManager.shared.configure()
    SocketIOManager.shared.configure()
    MessagesManager.shared.configure()
    InAppNotificationManager.shared.configure()
    
    // Register the client with the server (sends the client's uuid string)
    if let uuidString = UIDevice.current.identifierForVendor?.uuidString {
      SCConnectAPI.REST.Clients.registerClientWith(uuid: uuidString)
    }
    
    // Attempts to gain authorization for notifications every time app launches. This allows users to change notification settings in big settings and start getting notifications.
    if UserDefaults.standard.bool(forKey: UserDefaultsConstants.tutorialCompletedKey) {
      UNUserNotificationCenter.current().requestAuthorization(options: [.badge, .alert, .sound]) { (granted, error) in
        if granted {
          Log("Remote Notification permission granted.")
          UIApplication.shared.registerForRemoteNotifications() // Registers for notifications and, if successful, updates the server
        } else {
          Log("Remote Notification permission not granted.")
        }
      }
    }
    
    // Clear the push notifications badge.
    UIApplication.shared.applicationIconBadgeNumber = 0
    
    return true
  }
  
  /// Used to open a socket connection.
  func applicationDidBecomeActive(_ application: UIApplication) {
    SocketIOManager.shared.establishConnection()
  }
  
  /// Used to close the socket connection.
  func applicationDidEnterBackground(_ application: UIApplication) {
    SocketIOManager.shared.closeConnection()
  }
  
  /// Used to update the server with this client's remote notification token upon a successful registration.
  func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
    let pushTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)}) //convert token data to a string
    if let uuidString = UIDevice.current.identifierForVendor?.uuidString {
      SCConnectAPI.REST.Clients.updateClientWith(uuid: uuidString, addingPushNotificationToken: pushTokenString)
    }
  }
  
  /// Used to log the fact, if remote notification registration fails.
  func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
    Log("failed to reg for notifications with error, \(error)")
  }
  
  /// Used as middleware to forward all calls for opening a url onto GIDSignIn.
  func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance().handle(url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
  }
}

