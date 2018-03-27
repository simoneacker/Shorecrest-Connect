//
//  UserManager.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/16/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import Google
import GoogleSignIn

class UserManager: NSObject, GIDSignInDelegate {
  
  /// Singleton of `UserManager` class. Used bc it has sub-managers that should only have one instance for sake of staying in sync.
  public static let shared = UserManager()
  
  /// The instance of `GoogleManager` used to store and access Google Account info.
  private let googleManager = GoogleManager()
  
  /// The instance of `JWTManager` used to store and access authentication info.
  private let jwtManager = JWTManager()
  
  /// The instance of `GraduationYearManager` used to store and access selected graduation year info.
  private let graduationYearManager = GraduationYearManager()
  
  /// The instance of `SubscriptionsManager` used to store, access, and alter subscriptions.
  private let subscriptionsManager = SubscriptionsManager()
  
  /// The instance of `GoogleCalendarManager` used to create calendar events.
  private let googleCalendarManager = GoogleCalendarManager()
  
  /// Tracks whether or not the GIDSignIn library is in the process of attempting to sign into a Google Account.
  private var signInRequested = false
  
  /// Configures the Google libaries and sets up the sub-managers.
  public func configure() {
    var configureError: NSError?
    GGLContext.sharedInstance().configureWithError(&configureError)
    GIDSignIn.sharedInstance().delegate = self
    GIDSignIn.sharedInstance().scopes.append("https://www.googleapis.com/auth/calendar") // Request the calendar scope as well.
    
    googleManager.configure()
    jwtManager.configure()
    graduationYearManager.configure()
    subscriptionsManager.configure()
  }
  
  
  // MARK: - Sign in or out
  
  /// Used to request that the GIDSignIn library sign in a Google account.
  public func signIn() {
    if !signInRequested && GIDSignIn.sharedInstance().uiDelegate != nil {
      GIDSignIn.sharedInstance().signIn()
      signInRequested = true
    }
  }
  
  /// Used to request that the GIDSignIn library sign out the current Google account.
  public func signOut() {
    GIDSignIn.sharedInstance().disconnect()
  }
  
  
  // MARK: - Google Account Information
  
  /// Uses the `GoogleManager` function to check if a user is signed in.
  public func userSignedIn() -> Bool {
    
    return googleManager.userSignedIn()
  }
  
  /// Uses the `GoogleManager` function to grab the current user.
  public func getUser() -> GoogleUser? {
    
    return googleManager.getUser()
  }
  
  
  // MARK: - Authentication
  
  /// Checks if a user is signed in and the authentication info is valid.
  public func authenticationInfoIsValid() -> Bool {
    if googleManager.userSignedIn() {
      if jwtManager.currentTokenIsValid() {
        return true
      }
    }
    
    return false
  }
  
  /// If the current auth info is expired and needs to be refreshed, requests a silent sign in to get new info.
  public func refreshAuthenticationInfo() {
    if googleManager.userSignedIn() && !jwtManager.currentTokenIsValid() {
      if !signInRequested && GIDSignIn.sharedInstance().uiDelegate != nil {
        GIDSignIn.sharedInstance().signInSilently()
        signInRequested = true
      }
    }
  }
  
  /// Returns the current authentication info if a user is signed in and the auth info is valid.
  public func getAuthenticationInfo() -> JSONWebToken? {
    if googleManager.userSignedIn() {
      if jwtManager.currentTokenIsValid() {
        return jwtManager.getToken()
      }
    }
    
    return nil
  }
  
  
  // MARK: - Subscriptions
  
  /// Grabs the array of subscribed `Tag` models.
  public func getSubscribedTags() -> [Tag] {
    
    return subscriptionsManager.tags
  }
  
  /**
      Add the tag to local stores, updates the server, and sends an internal notifcation of the subscription change. Also joins room for subsribed tags.
   
      - Note: If the user is already subscribed to the given tag, nothing is changed or downloaded.
   
      - Parameters:
          - tagName: The name of tag being subscribed to.
   */
  public func subscribeTo(tagName: String) {
      subscriptionsManager.subscribeTo(tagName: tagName)
  }
  
  /**
      Removes the tag from local stores, updates the server, and sends an internal notifcation of the subscription change. Also leaves room for tag.
   
      - Note: If the user is not subscribed to the given tag, nothing is changed or downloaded.
   
      - Parameters:
          - tagName: The name of tag being subscribed to.
   */
  public func unsubscribeFrom(tagName: String) {
    subscriptionsManager.unsubscribeFrom(tagName: tagName)
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
    subscriptionsManager.updateColorFor(tagName: tagName, to: colorIndex, completion: completion)
  }
  
  /**
      Checks if the user is subscribed to the given tag by name.
   
      - Parameters:
          - tagName: The name of tag being checked for subscription status.
      - Returns: True if user is subscribed to tag name, otherwise false.
   */
  public func isSubscribedTo(tagName: String) -> Bool {
    
    return subscriptionsManager.isSubscribedTo(tagName: tagName)
  }
  
  
  // MARK: - Google Calendar
  
  /**
      If the access token exists, attempts to create a Google Calendar event for the signed in account.
   
      - Parameters:
          - startDate: The start date of the event.
          - endDate: The end date of the event.
          - eventTitle: The title of the event.
          - eventDescription: The description for the event.
          - completion: Called when the request is complete. Needs to accept a boolean that is true if successful creation, otherwise false.
   */
  public func createCalendarEvent(startDate: Date, endDate: Date, eventTitle: String, eventDescription: String, completion: ((Bool) -> ())?) {
    googleCalendarManager.createCalendarEvent(startDate: startDate, endDate: endDate, eventTitle: eventTitle, eventDescription: eventDescription, completion: completion)
  }
  
  
  // MARK: - Graduation Year
  
  /// Returns the currently selected graduation year if there is one.
  public func getGraduationYear() -> Int? {
    return graduationYearManager.getGraduationYear()
  }
  
  /**
      Sets the current graduation year if there is a user signed in. Also, attempts to unsubscribe from old grad year and subscribe to the new (subscriptions not validated though).
   
      - Parameters:
          - year: The selected graduation year that will be stored.
   */
  public func setGraduation(year: Int) {
    if googleManager.userSignedIn() {
      if let oldGraduationYear = graduationYearManager.getGraduationYear() {
        subscriptionsManager.unsubscribeFrom(tagName: "\(oldGraduationYear)")
      }
      graduationYearManager.setGraduation(year: year)
      subscriptionsManager.subscribeTo(tagName: "\(year)")
    }
  }
  
  
  // MARK: - UI Fuctions
  
  /// Creates and returns a UIAlertController with a message about the user needing to be signed in to do some action.
  public func notSignedInAlertController() -> UIAlertController {
    let alertController = UIAlertController(title: "Not Signed In", message: "You must be signed into an @k12.shorelineschoools.org account.", preferredStyle: .alert)
    let signInAction = UIAlertAction(title: "Sign In", style: .default) { [weak self] (action) in
      self?.signIn()
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(signInAction)
    alertController.addAction(cancelAction)
    
    return alertController
  }
  
  /// Creates and returns a UIAlertController with a message about the user not having permission for some action.
  public func permissionsIssueAlertController() -> UIAlertController {
    let alertController = UIAlertController(title: "Not Allowed", message: "You do not have permission to do that.", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
    alertController.addAction(okAction)
    
    return alertController
  }
  
  /// Creates and returns a UIAlertController with a message about the user needing to be subscribed to do some action.
  public func notSubscribedAlertController(tagName: String) -> UIAlertController {
    let alertController = UIAlertController(title: "Not Subscribed", message: "You must be subscribed to \(tagName).", preferredStyle: .alert)
    let subscribeAction = UIAlertAction(title: "Subscribe", style: .default) { [weak self] (action) in
      self?.subscriptionsManager.subscribeTo(tagName: tagName)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
    alertController.addAction(subscribeAction)
    alertController.addAction(cancelAction)
    
    return alertController
  }
  
  /// Creates and returns a UIAlertController with a message about the app being school property.
  public func schoolPropertyWarningAlertController() -> UIAlertController {
    let alertController = UIAlertController(title: "Reminder!", message: "This app is considered school property and all rules apply. Please only upload or post school appropriate content.", preferredStyle: .alert)
    let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
    alertController.addAction(okAction)
    
    return alertController
  }
  
  
  // MARK: - GIDSignInDelegate
  
  /// Used to update server, local stores, and to post an internal notification on a successful google sign in.
  func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
    if (error == nil) {
      print(user.authentication.accessToken)
      if user.profile.email.contains("k12.shorelineschools.org"), let uuidString = UIDevice.current.identifierForVendor?.uuidString { // Validate that it is a k12 acc
        SCConnectAPI.REST.Authentication.signInToGoogleAccountWith(authenticationToken: user.authentication.idToken, forClientWith: uuidString, completion: { [weak self] (jwtString) in
          if jwtString != nil {
            self?.jwtManager.setToken(encodedString: jwtString!)
            self?.googleManager.setUserWith(id: user.userID, email: user.profile.email, firstName: user.profile.givenName, lastName: user.profile.familyName) // After token gets set bc it downloads permissions using the new token.
            self?.subscriptionsManager.refreshSubscriptions()
            self?.googleCalendarManager.accessToken = user.authentication.accessToken
            if SocketIOManager.shared.isConnected() {
              SCConnectAPI.Socket.joinAllSubscribedRooms()
            }
            self?.signInRequested = false
          } else {
            signIn.disconnect()
            self?.signInRequested = false
          }
        })
      } else {
        signIn.disconnect()
        signInRequested = false
      }
    } else {
      Log("Error signing in user: \(error.localizedDescription)")
      signIn.disconnect()
      signInRequested = false
    }
  }
  
  /// Used to update server, local stores, and to post an internal notification on a successful google sign out.
  func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    if (error == nil) {
      SCConnectAPI.REST.Authentication.signOutFromGoogleAccount() // If token expire, call won't work and that doesn't matter since new token will need to be requested anyway.
      self.googleManager.removeUser()
      self.jwtManager.removeToken()
      self.graduationYearManager.removeGraduationYear()
      self.subscriptionsManager.refreshSubscriptions()
      self.googleCalendarManager.accessToken = nil
    } else {
      Log("Error signing out user: \(error.localizedDescription)")
    }
  }
}
