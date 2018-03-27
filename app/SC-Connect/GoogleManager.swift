//
//  GoogleManager.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 1/31/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation
import UIKit // for alert controller

/**
    Manages storing information about the signed in google account.
 
    - Note: The order of user info in the UserDefaults array is [google id, email, first name, last name, isModerator, isAdmin].
 */
class GoogleManager: NSObject {
  
  /// Object of `GoogleUser` class which has all the basic user information like google id, name, etc. Optional because nil if user is not logged in. 
  private var currentUser: GoogleUser?
  
  /// Loads the current user info from file.
  public func configure() {
    if let userFromDefaults = UserDefaults.standard.array(forKey: UserDefaultsConstants.googleUserInfoKey) { // Grab user info from file
      if let userInfoFromDefaults = Array(userFromDefaults[0...3]) as? [String] {
        if let userPermissionsFromDefaults = Array(userFromDefaults[4...5]) as? [Bool] {
          currentUser = GoogleUser(googleID: userInfoFromDefaults[0], email: userInfoFromDefaults[1], firstName: userInfoFromDefaults[2], lastName: userInfoFromDefaults[3], isModerator: userPermissionsFromDefaults[0], isAdmin: userPermissionsFromDefaults[1])
        }
      }
    }
  }
  
  /// Returns the currently signed in user.
  public func getUser() -> GoogleUser? {
    
    return currentUser
  }
  
  /**
      Sets the information about the current Google Account and downloads the user's permissions.
  
      - Parameters:
          - googleID: The identifier of the Google Account.
          - email: The email of the Google Account.
          - firstName: The first name of the Google Account.
          - lastName: The last name of the Google Account.
   */
  public func setUserWith(id googleID: String, email: String, firstName: String, lastName: String) {
    currentUser = GoogleUser(googleID: googleID, email: email, firstName: firstName, lastName: lastName, isModerator: false, isAdmin: false)
    SCConnectAPI.REST.Authentication.getUserPermissions(completion: { [weak self] (isModerator, isAdmin) in //download permissions
      self?.currentUser?.isModerator = isModerator
      self?.currentUser?.isAdmin = isAdmin
      UserDefaults.standard.set([googleID, email, firstName, lastName, isModerator, isAdmin], forKey: UserDefaultsConstants.googleUserInfoKey)
      NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.googleUserSignedInKey), object: nil)
      Log("User signed in successfully.")
    })
  }
  
  /// Clears the currently signed in user information.
  public func removeUser() {
    currentUser = nil
    UserDefaults.standard.removeObject(forKey: UserDefaultsConstants.googleUserInfoKey)
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.googleUserSignedOutKey), object: nil)
    Log("User disconnected successfully.")
  }
  
  /// Returns true if user is signed in or false if no user is signed in.
  /// - Note: This guarantees that the user is not nil.
  public func userSignedIn() -> Bool {
    if currentUser != nil {
      return true
    }
    
    return false
  }
}
