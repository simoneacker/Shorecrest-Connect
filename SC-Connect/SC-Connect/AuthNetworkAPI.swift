//
//  AuthenticatedNetworkAPI.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 4/29/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation


/**
    The level of abstraction below the SC-Connect APIs, but above the actual web requests, that adds JSON Web Token authentication information to network calls.
 
    - Note: All functions are static so they can be called without initializing a `SessionNetworkAPI` object.
    - Note: JSON Web Token authentication info is taken from the shared instance of the `UserManager` class.
 */
struct AuthenticatedNetworkAPI {
  
  /**
      Creates a JWT authenticated GET query URL from the `NetworkConstants.baseURL`, a string addition, a dictionary of string parameters, and current auth info.
   
      - Parameters:
          - urlPathAddition: A string addition to the URL path.
          - parameters: An optional string dictionary that will be formatted to form the end of the query URL. Dictionary keys should used camelCase.
      - Returns: An optional URL.
   */
  public static func makeGETQueryURLToBasePathWith(pathAddition: String, parameters: [String: String]?, shouldRefreshAuthIfExpired: Bool) -> URL? {
    
    // Grab current JWT info, if exists,
    if let authToken = UserManager.shared.getAuthenticationInfo() {
      
      // Add auth info to parameters
      var parametersWithAuthenticationInfo = parameters ?? [String: String]() // Need to have a dict to put auth info into
      parametersWithAuthenticationInfo["authToken"] = authToken.encodedString
      
      // Call normal get request generator to return a url
      return NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: pathAddition, parameters:parametersWithAuthenticationInfo)
    } else if UserManager.shared.userSignedIn() && shouldRefreshAuthIfExpired {
      UserManager.shared.refreshAuthenticationInfo()
      DebugLog("makeAuthenticatedGETQueryURLToBasePathWith failed. Valid authentication info expired. Authentication info refresh started.")
      return nil
    } else {
      DebugLog("makeAuthenticatedGETQueryURLToBasePathWith failed. Valid authentication info unavailable.")
      return nil
    }
  }
  
  /**
      Creates, sends, and handles a JWT authenticated POST request to the given URL.
   
      - Note: The body of the POST request is converted to and sent as JSON.
      - Note: Status code -2 returned if invalid auth info. Status code -1 returned for other errors.
      - Parameters:
          - url: The query url that information is requested from.
          - body: A dictionary of info that will be JSON encoded and passed as the body of the POST request. All keys should be lowercase and each word should be separated by an underscore.
          - completion: The handler called when the web request is completed. Needs to accept an http status code from the response.
   */
  public static func POSTRequestTo(url: URL, with body: [String: Any]?, shouldRefreshAuthIfExpired: Bool, completion: @escaping (Int) -> ()) {
    
    // Grab current JWT info, if exists,
    if let authToken = UserManager.shared.getAuthenticationInfo() {
      
      // Add auth info to body
      var bodyWithAuthenticationInfo = body ?? [String: Any]() // Need to have a dict to put auth info into
      bodyWithAuthenticationInfo["auth_token"] = authToken.encodedString
      
      // Call normal post request and pass completion so it passes the result back to the sender
      NetworkAPI.POSTRequestTo(url: url, with: bodyWithAuthenticationInfo, completion: completion)
      
    } else if UserManager.shared.userSignedIn() && shouldRefreshAuthIfExpired {
      UserManager.shared.refreshAuthenticationInfo()
      DebugLog("authenticatedPOSTRequestTo failed. Valid authentication info expired. Authentication info refresh started.")
      completion(-2)
    } else {
      DebugLog("authenticatedPOSTRequestTo failed. Valid authentication info unavailable.")
      completion(-2)
    }
  }
  
  /**
      Creates, sends, handles, and parses a JWT Authenticated POST request to the given URL.
   
      - Note: The body of the POST request is converted to and sent as JSON.
      - Note: The response data from the request is expected to be in JSON format. This method parses the json into a dictionary for easier use.
      - Note: Status code -2 returned if invalid auth info. Status code -1 returned for other errors.
      - Parameters:
          - url: The query url that information is requested from.
          - body: A dictionary of info that will be JSON encoded and passed as the body of the POST request. All keys should be lowercase and each word should be separated by an underscore.
          - completion: The handler called when the web request is completed. Needs to accept an http status code from the response and a dictionary of the parsed response data.
   */
  public static func POSTRequestWithDataResponseTo(url: URL, with body: [String: Any]?, shouldRefreshAuthIfExpired: Bool, completion: @escaping (Int, [String: Any]?) -> ()) {
    
    // Grab current JWT info, if exists,
    if let authToken = UserManager.shared.getAuthenticationInfo() {
      
      // Add auth info to body
      var bodyWithAuthenticationInfo = body ?? [String: Any]() // Need to have a dict to put auth info into
      bodyWithAuthenticationInfo["auth_token"] = authToken.encodedString
      
      // Call normal post request and pass completion so it passes the result back to the sender
      NetworkAPI.POSTRequestWithDataResponseTo(url: url, with: bodyWithAuthenticationInfo, completion: completion)
      
    } else if UserManager.shared.userSignedIn() && shouldRefreshAuthIfExpired {
      UserManager.shared.refreshAuthenticationInfo()
      DebugLog("authenticatedPOSTRequestWithDataResponseTo failed. Valid authentication info expired. Authentication info refresh started.")
      completion(-2, nil)
    } else {
      DebugLog("authenticatedPOSTRequestWithDataResponseTo failed. Valid authentication info unavailable.")
      completion(-2, nil)
    }
  }
}
