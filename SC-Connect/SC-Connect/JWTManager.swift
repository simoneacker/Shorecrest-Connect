//
//  JWTManager.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 4/28/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/**
    Manages storing, parsing, and validating JSON Web Token information. The JWT info is used to authenticate the client with the server.
 
    - Note: The shared info should always be in sync with the `GoogleManager` shared instance. If a user is signed in, there should be an authentication token and vice versa.
 */
class JWTManager: NSObject {
  
  /// Stores the current JWT token for the app.
  private var token: JSONWebToken?
  
  /// Used to load the current token from file.
  public func configure() {
    if let encodedString = UserDefaults.standard.string(forKey: UserDefaultsConstants.jwtKey) {
      setToken(encodedString: encodedString)
    }
  }
  
  /// Returns the current token if it is valid.
  public func getToken() -> JSONWebToken? {
    if currentTokenIsValid() {
      return token
    }
    
    return nil
  }
  
  /**
      Parses a JWT encoded token string into a `JSONWebToken` and sets the current token.
   
      - Parameters:
          - encodedString: The JSON Web Token given by the server that will be parsed and saved.
   */
  public func setToken(encodedString: String) {
    let base64EncodedTokenParts = encodedString.components(separatedBy: ".")
    if base64EncodedTokenParts.count == 3 {
      token = JSONWebToken()
      token?.encodedString = encodedString // Could force unwrap token bc just set but no reason to do so
      token?.signature = base64EncodedTokenParts[2]
      if let headerDictionary = decodeBase64Encoded(jsonDictionaryString: base64EncodedTokenParts[0]) {
        token?.header = headerDictionary
      }
      if let payloadDictionary = decodeBase64Encoded(jsonDictionaryString: base64EncodedTokenParts[1]) {
        token?.payload = payloadDictionary
      }
      
      UserDefaults.standard.set(encodedString, forKey: UserDefaultsConstants.jwtKey)
    } else {
      Log("Failed to set token. Invalid encoded string passed.")
    }
  }
  
  /// Clears the token store.
  public func removeToken() {
    token = nil
    UserDefaults.standard.removeObject(forKey: UserDefaultsConstants.jwtKey)
  }
  
  /**
      Checks if current token exists and if the exp date is in the future.
   
      - Returns: True is the token exists/is valid or false otherwise.
   */
  public func currentTokenIsValid() -> Bool {
    if let currentToken = token {
      if let expirationDateSecondsSince1970Int = currentToken.payload["exp"] as? Int {
        let expirationDate = Date(timeIntervalSince1970: Double(expirationDateSecondsSince1970Int))
        if expirationDate > Date() {
          return true
        }
      }
    }
    
    return false
  }
  
  /**
      Decodes a base64 encoded string, which should be a json dictionary, into a swift dictionary.
   
      - Note: Pads input string with extra characters to make its character count a multiple of 4, which is necessary based on Foundation's implementation of base 64 decode. Padding method altered from jlasierra's answer on http://stackoverflow.com/questions/36364324/swift-base64-decoding-returns-nil
   
      - Parameters:
          - jsonDictionaryString: String that should contain a dictionary as JSON.
      - Returns: The dictionary parsed from the JSON string.
   */
  private func decodeBase64Encoded(jsonDictionaryString: String) -> [String: Any]? {
    do {
      let paddedJSONDictionaryString = jsonDictionaryString.padding(toLength: ((jsonDictionaryString.characters.count + 1) / 4) * 4, withPad: "=", startingAt: 0)
      if let jsonStringData = Data(base64Encoded: paddedJSONDictionaryString) {
        if let dictionaryParsedFromJSONData = try JSONSerialization.jsonObject(with: jsonStringData, options: .allowFragments) as? [String: Any] {
          return dictionaryParsedFromJSONData
        } else {
          Log("Error decoding base 64 encoded json dictionary string to dictionary object. Could not deserialize the json.")
        }
      } else {
        Log("Error decoding base 64 encoded json dictionary string to dictionary object. Given string is invalid base64.")
      }
    } catch let error {
      Log("Error decoding base 64 encoded json dictionary string to dictionary object. Error: \(error).")
    }
    
    return nil
  }
}
