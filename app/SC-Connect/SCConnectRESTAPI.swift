//
//  APIManager.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 3/12/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation

/**
    The REST (HTTP) Application Program Interface (API) between the SC-Connect iOS App and backend server.
 
    - Note: All functions are static so they can be called without initializing a `SCConnectRESTAPI` object.
    - Note: The API is built using tiers of structs in order to categorize different requests and make requests super simple (ex. SCConnectRESTAPI.Client.registerClientWith(uuid:)  ).
 */
struct SCConnectRESTAPI {
  
  /// The API category for calls used to keep the server updated about the device/push notifications and the google user signed into it.
  struct Clients {
    
    /**
        Sends a POST request to the server registering the client (by uuid).
     
        - Note: There is no return or completion handler because the response is just used to log whether or not registration was successful.
        
        - Parameters:
            - uuid: The 36 character unique identifier for the client. This should be grabbed using Apple's UIDevice api.
     */
    public static func registerClientWith(uuid: String) {
      if uuid.characters.count == 36 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "clients/register/") {
          NetworkAPI.POSTRequestTo(url: url, with: ["uuid": uuid], completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("Registration successful.")
              case 200:
                Log("Client already registered.")
              default:
                Log("Registration failed with status code: \(statusCode).")
            }
          })
        } else {
          Log("Registration failed. URL could not be created.")
        }
      } else {
        Log("Registration failed. UUID was wrong length.")
      }
    }
    
    /**
        Sends a POST request to the server updating the push notification token for the client (by uuid).
     
        - Note: There is no return or completion handler because the response is just used to log whether or not the update was successful.
     
        - Parameters:
            - uuid: The 36 character unique identifier for the client. This should be grabbed using Apple's UIDevice api.
            - token: Push notification token used to send remote notifications to the user. This should be grabbed using Apple's remote notification api.
     */
    public static func updateClientWith(uuid: String, addingPushNotificationToken token: String) {
      if uuid.characters.count == 36 && token.characters.count == 64 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "clients/updatePushToken/") {
          NetworkAPI.POSTRequestTo(url: url, with: ["uuid": uuid, "push_token": token], completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("Push token updated successfully.")
              default:
                Log("Push token update failed with status code: \(statusCode).")
            }
          })
        } else {
          Log("Push token update failed. URL could not be created.")
        }
      } else {
        Log("Push token update failed. UUID or push token was wrong length.")
      }
    }
  }
  
  /// The API category for calls used to sign in and sign out. Signing in returns new authentication info and signing out makes the current info invalid.
  struct Authentication {
    
    /**
        Sends a POST request to the server telling it that the user has signed into a Google account locally. If the update is successful, the server will return a new JSON Web Token for the client, which will be used to authenticate the client with the server.
     
        - Note: The JSON Web Token is passed back as a string through the completion handler.
     
        - Parameters:
            - idToken: Authentication id token given by the google libraries when the user logged in locally. This allows the server to fetch information about the user for its own stores.
            - uuid: The 36 character unique identifier for the client. This should be grabbed using Apple's UIDevice api.
            - completion: The handler called when the POST request is completed. Needs to accept an optional String.
     */
    public static func signInToGoogleAccountWith(authenticationToken idToken: String, forClientWith uuid: String, completion: @escaping (String?) -> ()) {
      if uuid.characters.count == 36 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "clients/signInToGoogleAccount/") {
          NetworkAPI.POSTRequestWithDataResponseTo(url: url, with: ["uuid": uuid, "google_id_token": idToken], completion: { (statusCode, responseDictionary) in
            if let jsonWebTokenString = responseDictionary?["json_web_token"] as? String {
              Log("Request to sign into google account succeeded. New authentication information was returned.")
              completion(jsonWebTokenString)
            } else {
              Log("Request to sign into google account failed. No authentication token was returned.")
              completion(nil)
            }
          })
        } else {
          Log("Request to sign into google account failed. URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Request to sign into google account failed. UUID was wrong length.")
        completion(nil)
      }
    }
    
    /**
        Sends a POST request to the server telling it that the user has signed out from the Google account locally. This makes the current authentication info invalid because the server knows that no Google account is signed in for this client.
     
        - Note: There is no completion bc whether or not the server knows that the client signed out, the client can clear its stores and when signing in, the server will clear the old info.
     */
    public static func signOutFromGoogleAccount() {
      if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "clients/signOutFromGoogleAccount/") {
        AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: nil, shouldRefreshAuthIfExpired: false, completion: { (statusCode) in
          switch statusCode {
            case 201:
              Log("Successfully signed out from Google account. Current authentication info is no longer valid.")
            default:
              Log("Attempt to sign out from Google account failed with status code: \(statusCode).")
          }
        })
      } else {
        Log("Attempt to sign out from Google account failed. URL could not be created.")
      }
    }
    
    /**
        Sends a GET request to the server asking for the moderator and admin permissions of the signed in user.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept two boolean values. First = isModerator, second = isAdmin. Both defaul to false if something went wrong in the request.
     */
    public static func getUserPermissions(completion: @escaping (Bool, Bool) -> ()) {
      if let url = AuthenticatedNetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "clients/GoogleAccountPermissions/", parameters: nil, shouldRefreshAuthIfExpired: true) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let moderatorBool = responseDictionary?["moderator"] as? Bool, let adminBool = responseDictionary?["admin"] as? Bool {
            Log("Successfully grabbed and parsed user permissions.")
            completion(moderatorBool, adminBool)
          } else {
            Log("Failed to get user permissions. Moderator or admin bools not returned.")
            completion(false, false)
          }
        })
      } else {
        Log("Failed to get user permissions. URL could not be created.")
        completion(false, false)
      }
    }
  }

  /// The API category for calls used to subscribe and unsubscribe from tags.
  struct Subscriptions {
    
    /**
        Sends a POST request to the server telling it that the user wants to subscribe to the given tag.
     
        - Parameters:
            - tagName: Name of the tag being subscribed to.
            - completion: The handler called when the POST request is completed. Needs to accept a bool that tells if subscription was successful.
     */
    public static func subscribeToTagWith(name tagName: String, completion: @escaping (Bool) -> ()) {
      if tagName.characters.count <= 8 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "subscriptions/subscribeToTag/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["tag_name": tagName], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
            case 201, 200: // Encompasses both new and existing subscription bc still subscribed to that tag.
              Log("Successfully subscribed to tag (\(tagName)).")
              completion(true)
            default:
              Log("Attempt to subscribe to tag (\(tagName)) failed with status code: \(statusCode).")
              completion(false)
            }
          })
        } else {
          Log("Attempt to subscribe to tag (\(tagName)) failed. URL could not be created.")
          completion(false)
        }
      } else {
        Log("Attempt to subscribe to tag (\(tagName)) failed. Tag name was too long.")
        completion(false)
      }
    }
    
    /**
        Sends a POST request to the server telling it that the user wants to unsubscribe from the given tag.
     
        - Parameters:
            - tagName: Name of the tag being unsubscribed from.
            - completion: The handler called when the POST request is completed. Needs to accept a bool that tells if unsubscription was successful.
     */
    public static func unsubscribeFromTagWith(name tagName: String, completion: @escaping (Bool) -> ()) {
      if tagName.characters.count <= 8 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "subscriptions/unsubscribeFromTag/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["tag_name": tagName], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
            case 201, 200: // Encompasses both new unsub and existing unsubscription bc still not subscribed to that tag.
              Log("Successfully unsubscribed from tag (\(tagName)).")
              completion(true)
            default:
              Log("Attempt to unsubscribe from tag (\(tagName)) failed with status code: \(statusCode).")
              completion(false)
            }
          })
        } else {
          Log("Attempt to unsubscribe from tag (\(tagName)) failed. URL could not be created.")
          completion(false)
        }
      } else {
        Log("Attempt to unsubscribe from tag (\(tagName)) failed. Tag name was too long.")
        completion(false)
      }
    }
    
    /**
        Sends a GET request to the server asking for the names of all tags that the user is subscribed to.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of strings.
     */
    public static func getAllSubscribedTagNames(completion: @escaping ([String]?) -> ()) {
      if let url = AuthenticatedNetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "subscriptions/allSubscribedTagNames/", parameters: nil, shouldRefreshAuthIfExpired: true) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let tagNames = responseDictionary?["tag_names"] as? [String] {
            Log("Successfully grabbed and parsed all subscribed tag names.")
            completion(tagNames)
          } else {
            Log("Failed to get all subscribed tag names. Array of tag names was not returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get all subscribed tag names. URL could not be created.")
        completion(nil)
      }
    }
  }
  
  /// The API category for calls used to download information about leaderboard scores.
  struct LeaderboardScores {
    
    /**
        Sends a GET request to the server asking for all leaderboard scores.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `LeaderboardScore` models.
     */
    public static func getAllLeaderboardScores(completion: @escaping ([LeaderboardScore]?) -> ()) {
      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "leaderboard/scores/", parameters: nil) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let leaderboardScoreDictionaries = responseDictionary?["leaderboard_scores"] as? [NSDictionary] {
            let leaderboardScoreModels = parseLeaderboardScoreModelsFrom(leaderboardScoreDictionaries: leaderboardScoreDictionaries)
            Log("Successfully grabbed and parsed all leaderboard scores.")
            completion(leaderboardScoreModels)
          } else {
            Log("Failed to get all leaderboard scores. Array of leaderboard score dictionaries was not returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get all leaderboard scores. URL could not be created.")
        completion(nil)
      }
    }
    
    /**
        Sends a GET request to the server asking for the total number of graduation points for each current graduating class.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `LeaderboardTotal` models.
     */
    public static func getLeaderboardPointTotalsForEachGraduationYear(completion: @escaping ([LeaderboardTotal]?) -> ()) {
      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "leaderboard/graduationYearTotals/", parameters: nil) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let leaderboardTotalDictionaries = responseDictionary?["graduation_year_totals"] as? [NSDictionary] {
            let leaderboardTotalModels = parseLeaderboardTotalModelsFrom(leaderboardTotalDictionaries: leaderboardTotalDictionaries)
            Log("Successfully grabbed and parsed all leaderboard point totals for each graduation year.")
            completion(leaderboardTotalModels)
          } else {
            Log("Failed to get all leaderboard point totals for each graduation year. No totals returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get all leaderboard point totals for each graduation year. URL could not be created.")
        completion(nil)
      }
    }
    
    /**
        Sends a GET request to the server asking for the list of available graduation years.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional Integer array.
     */
    public static func getAvailableGraduationYears(completion: @escaping ([Int]?) -> ()) {
      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "leaderboard/availableGraduationYears/", parameters: nil) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let availableGraduationYears = responseDictionary?["available_graduation_years"] as? [Int] {
            Log("Successfully grabbed and parsed all available graduation years.")
            completion(availableGraduationYears)
          } else {
            Log("Failed to get all available graduation years. No years returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get all available graduation years. URL could not be created.")
        completion(nil)
      }
    }
    
    /**
        Parses an array of leaderboard score dictionaries into an array of `LeaderboardScore` models.
     
        - Parameters:
            - leaderboardScoreDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `LeaderboardScore` model.
     
        - Returns: An array of `LeaderboardScore` models.
     */
    private static func parseLeaderboardScoreModelsFrom(leaderboardScoreDictionaries: [NSDictionary]) -> [LeaderboardScore] {
      var leaderboardScoresArray = [LeaderboardScore]()
      for leaderboardScoreDict in leaderboardScoreDictionaries {
        var leaderboardScore = LeaderboardScore()
        if let leaderboardScoreID = leaderboardScoreDict["leaderboard_score_id"] as? Int {
          leaderboardScore.leaderboardScoreID = leaderboardScoreID
        }
        if let score = leaderboardScoreDict["leaderboard_score"] as? Int {
          leaderboardScore.score = score
        }
        if let firstName = leaderboardScoreDict["first_name"] as? String {
          if let lastName = leaderboardScoreDict["last_name"] as? String {
            leaderboardScore.username = "\(firstName) \(lastName)"
          }
        }
        leaderboardScoresArray.append(leaderboardScore)
      }
      
      return leaderboardScoresArray
    }
    
    /**
        Parses an array of leaderboard total dictionaries into an array of `LeaderboardTotal` models.
     
        - Parameters:
            - leaderboardTotalDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `LeaderboardTotal` model.
     
        - Returns: An array of `LeaderboardTotal` models.
     */
    private static func parseLeaderboardTotalModelsFrom(leaderboardTotalDictionaries: [NSDictionary]) -> [LeaderboardTotal] {
      var leaderboardTotalsArray = [LeaderboardTotal]()
      for leaderboardTotalDict in leaderboardTotalDictionaries {
        var leaderboardTotal = LeaderboardTotal()
        if let graduationYear = leaderboardTotalDict["graduation_year"] as? Int {
          leaderboardTotal.graduationYear = graduationYear
        }
        if let pointsTotal = leaderboardTotalDict["points_total"] as? Int {
          leaderboardTotal.totalPoints = pointsTotal
        }
        leaderboardTotalsArray.append(leaderboardTotal)
      }
      
      return leaderboardTotalsArray
    }
  }
  
  /// The API category for calls used to download tag information, create a tag, or upload changes to a tag.
  struct Tags {
    
    /**
        Sends a GET request to the server asking for information about a tag (by name).
      
        - Parameters:
            - name: The name of the requested tag. Should be 1 to 8 characters in length.
            - completion: The handler called when the GET request is completed. Needs to accept an optional `Tag` model.
     */
    public static func getInfoForTagWith(name tagName: String, completion: @escaping (Tag?) -> ()) {
      if tagName.characters.count <= 8 {
        if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "tags/info/", parameters: ["tagName": tagName]) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let tagDictionary = responseDictionary?["tag"] as? NSDictionary {
              let tagModelsParsedFromDictionary = parseTagModelsFrom(tagDictionaries: [tagDictionary])
              if tagModelsParsedFromDictionary.count == 1 {
                Log("Successfully grabbed and parsed info about tag (\(tagName)).")
                completion(tagModelsParsedFromDictionary[0])
              } else {
                Log("Failed to get info about tag: \(tagName). More than one tag returned or tag dictionary parse failed.")
                completion(nil)
              }
            } else {
              Log("Failed to get info about tag: \(tagName). No tag dictionaries returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to get info about tag: \(tagName). URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to get info about tag: \(tagName). Tag name was too long.")
        completion(nil)
      }
    }
    
    /**
        Sends a GET request to the server asking for the subscriber count of the tag (by name).
     
        - Parameters:
            - name: The name of the requested tag. Should be 1 to 8 characters in length.
            - completion: The handler called when the GET request is completed. Needs to accept an optional integer subscriber count.
     */
    public static func getSubscriberCountForTagWith(name tagName: String, completion: @escaping (Int?) -> ()) {
      if tagName.characters.count <= 8 {
        if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "tags/subscriberCount/", parameters: ["tagName": tagName]) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let subscriberCount = responseDictionary?["subscriber_count"] as? Int {
              Log("Successfully grabbed and parsed subscriber count for tag (\(tagName)).")
              completion(subscriberCount)
            } else {
              Log("Failed to get subscriber count for tag: \(tagName). Subscriber count not returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to get info about tag: \(tagName). URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to get info about tag: \(tagName). Tag name was too long.")
        completion(nil)
      }
    }
    
    /**
        Sends a GET request to the server asking for the most popular tags.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `Tag` models.
     */
    public static func getTopTags(completion: @escaping ([Tag]?) -> ()) {
      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "tags/topTags/", parameters: nil) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let tagDictionaries = responseDictionary?["tags"] as? [NSDictionary] {
            let tagModelsParsedFromDictionary = parseTagModelsFrom(tagDictionaries: tagDictionaries)
            Log("Successfully grabbed and parsed top tags.")
            completion(tagModelsParsedFromDictionary)
          } else {
            Log("Failed to get top tags. No tag dictionaries returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get top tags. URL could not be created.")
        completion(nil)
      }
    }
    
    /**
        Sends a GET request to the server asking for all tags.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `Tag` models.
     */
    public static func getAllTags(completion: @escaping ([Tag]?) -> ()) {
      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "tags/all/", parameters: nil) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let tagDictionaries = responseDictionary?["tags"] as? [NSDictionary] {
            let tagModelsParsedFromDictionary = parseTagModelsFrom(tagDictionaries: tagDictionaries)
            Log("Successfully grabbed and parsed all tags.")
            completion(tagModelsParsedFromDictionary)
          } else {
            Log("Failed to get all tags. No tag dictionaries returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get all tags. URL could not be created.")
        completion(nil)
      }
    }
    
    
    /**
        Sends a GET request to the server asking for any tags that contain the search term.
     
        - Parameters:
            - searchTerm: The search term which each returned tag should contain.
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `Tag` models.
     */
    public static func getTagsContaining(searchTerm: String, completion: @escaping ([Tag]?) -> ()) {
      if searchTerm.characters.count <= 8 {
        if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "tags/tagsContainingSearchTerm/", parameters: ["searchTerm": searchTerm]) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let tagDictionaries = responseDictionary?["tags"] as? [NSDictionary] {
              let tagModelsParsedFromDictionary = parseTagModelsFrom(tagDictionaries: tagDictionaries)
              Log("Successfully grabbed and parsed tags containing search term (\(searchTerm)).")
              completion(tagModelsParsedFromDictionary)
            } else {
              Log("Failed to get tags containing term: \(searchTerm). No tag dictionaries returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to get tags containing term: \(searchTerm). URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to get tags containing term: \(searchTerm). Search term was too long.")
        completion(nil)
      }
    }
    
    /**
        Sends a POST request to the server updating the color index of the tag (by name).
     
        - Parameters:
            - name: The name of the requested tag. Should be 1 to 8 characters in length.
            - colorIndex: The index of the new color for the tag. Should be between 0 and 14.
            - completion: The handler called when the POST request is completed. Needs to accept a boolean value with true for successful update or false for unsuccessful update.
     */
    public static func updateTagWith(name tagName: String, addingNewColorIndex colorIndex: Int, completion: @escaping (Bool) -> ()) {
      if colorIndex >= 0 && colorIndex < 15 && tagName.characters.count <= 8 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "tags/updateColor/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["tag_name": tagName, "color_index": colorIndex], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("Successfully updated color index for tag with name: \(tagName).")
                completion(true)
              default:
                Log("Failed to update color index for tag with name: \(tagName) with status code: \(statusCode).")
                completion(false)
            }
          })
        } else {
          Log("Failed to update color index for tag (\(tagName)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to update color index for tag (\(tagName)). Invalid color index or tag name was too long.")
        completion(false)
      }
    }
    
    
    /**
        Sends a POST request to the server creating a tag (by name) and giving it a color index.
     
        - Note: Needs to receive a filled in `Tag` model in response.
     
        - Parameters:
            - name: The name of the requested tag. Should be 1 to 8 characters in length.
            - colorIndex: The index of the new color for the tag. Should be between 0 and 14.
            - completion: The handler called when the POST request is completed. Needs to accept an optional `Tag` model.
     */
    public static func createTagWith(name tagName: String, colorIndex: Int, completion: @escaping (Tag?) -> ()) {
      if tagName.characters.count > 0 && tagName.characters.count <= 8 && colorIndex >= 0 && colorIndex < 15 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "tags/create/") {
          AuthenticatedNetworkAPI.POSTRequestWithDataResponseTo(url: url, with: ["tag_name": tagName, "color_index": colorIndex], shouldRefreshAuthIfExpired: true, completion: { (statusCode, responseDictionary) in
            if let tagDictionary = responseDictionary?["tag"] as? NSDictionary {
              let tagModelsParsedFromDictionary = parseTagModelsFrom(tagDictionaries: [tagDictionary])
              if tagModelsParsedFromDictionary.count == 1 {
                Log("Successfully created and received filled in info about tag (\(tagName)).")
                completion(tagModelsParsedFromDictionary[0])
              } else {
                Log("Failed to create tag (\(tagName)). More than one filled in tag returned or tags dictionary parse failed.")
                completion(nil)
              }
            } else {
              Log("Failed to create tag (\(tagName)). No filled in tags dictionaries returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to create tag (\(tagName)). URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to create tag (\(tagName)). Invalid color index or tag name was too long.")
        completion(nil)
      }
    }
    
    /**
        Parses an array of tag dictionaries into an array of `Tag` models.
     
        - Parameters:
            - tagDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `Tag` model.
     
        - Returns: An array of `Tag` models.
     */
    private static func parseTagModelsFrom(tagDictionaries: [NSDictionary]) -> [Tag] {
      var tagsArray = [Tag]()
      for tagDict in tagDictionaries {
        var tag = Tag()
        if let tagID = tagDict["tag_id"] as? Int {
          tag.tagID = tagID
        }
        if let tagName = tagDict["tag_name"] as? String {
          tag.tagName = tagName
        }
        if let colorIndex = tagDict["color_index"] as? Int {
          tag.colorIndex = colorIndex
        }
        if let messageCount = tagDict["message_count"] as? Int {
          tag.messageCount = messageCount
        }
        tagsArray.append(tag)
      }
      
      return tagsArray
    }
  }
  
  
  
  /// The API category for calls used to download message information or upload a new message.
  struct Messages {
    
//    /**
//        Sends a POST request to the server creating a pure message on the given tag (by name).
//     
//        - Note: Needs to receive a filled in `SkeletonMessage` model in response.
//     
//        - Parameters:
//            - name: The name of the requested tag. Should be 1 to 8 characters in length.
//            - message: The text body for the pure message.
//            - completion: The handler called when the POST request is completed. Needs to accept an optional `SkeletonMessage` model.
//     */
//    public static func createMessageOnTagWith(name tagName: String, includingPureMessage message: String, completion: @escaping (SkeletonMessage?) -> ()) {
//      if message.characters.count > 0 && message.characters.count < 350 && tagName.characters.count <= 8 {
//        if let messageBodyJSONString = Helper.encodeDictionaryIntoJSONString(dictionary: ["pure_message": ["text": message]]) {
//          if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "messages/create/") {
//            AuthenticatedNetworkAPI.POSTRequestWithDataResponseTo(url: url, with: ["tag_name": tagName, "message_body": messageBodyJSONString], completion: { (statusCode, responseDictionary) in
//              if let messageDictionary = responseDictionary?["message"] as? NSDictionary {
//                let messageModelsParsedFromDictionary = parseMessageModelsFrom(messageDictionaries: [messageDictionary])
//                if messageModelsParsedFromDictionary.count == 1 {
//                  Log("Successfully created pure message and recieved a filled in message in response.")
//                  completion(messageModelsParsedFromDictionary[0])
//                } else {
//                  Log("Failed to create message. More than one filled in message returned or messages dictionary parse failed.")
//                  completion(nil)
//                }
//              } else {
//                Log("Failed to create message. No filled in message dictionaries returned.")
//                completion(nil)
//              }
//            })
//          } else {
//            Log("Failed to create message. URL could not be created.")
//            completion(nil)
//          }
//        } else {
//          Log("Failed to create message. Could not parse body into json string.")
//          completion(nil)
//        }
//      } else {
//        Log("Failed to create message. Invalid message length or tag name was too long.")
//        completion(nil)
//      }
//    }
//    
//    /**
//        Sends a POST request to the server creating a photo message on the given tag (by name).
//     
//        - Note: Needs to receive a filled in `SkeletonMessage` model in response in order to give local stores the correct message id and such.
//     
//        - Parameters:
//            - user: The `GoogleUser` model filled with the information from the currently logged in Google account.
//            - tagName: The name of the requested tag. Should be 1 to 8 characters in length.
//            - photoKey: The key for the photo in the AWS bucket. Will be included in the message body.
//            - completion: The handler called when the POST request is completed. Needs to accept an optional `SkeletonMessage` model.
//     */
//    public static func createMessageOnTagWith(name tagName: String, includingPhotoKey photoKey: String, completion: @escaping (SkeletonMessage?) -> ()) {
//      if tagName.characters.count <= 8 {
//        if let messageBodyJSONString = Helper.encodeDictionaryIntoJSONString(dictionary: ["photo_message": ["photo_key": photoKey]]) {
//          if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "messages/create/") {
//            AuthenticatedNetworkAPI.POSTRequestWithDataResponseTo(url: url, with: ["tag_name": tagName, "message_body": messageBodyJSONString], completion: { (statusCode, responseDictionary) in
//              if let messageDictionary = responseDictionary?["message"] as? NSDictionary {
//                let messageModelsParsedFromDictionary = parseMessageModelsFrom(messageDictionaries: [messageDictionary])
//                if messageModelsParsedFromDictionary.count == 1 {
//                  Log("Successfully created photo message and recieved a filled in message in response.")
//                  completion(messageModelsParsedFromDictionary[0])
//                } else {
//                  Log("Failed to create photo message. More than one filled in message returned or messages dictionary parse failed.")
//                  completion(nil)
//                }
//              } else {
//                Log("Failed to create photo message. No filled in message dictionaries returned.")
//                completion(nil)
//              }
//            })
//          } else {
//            Log("Failed to create photo message. URL could not be created.")
//            completion(nil)
//          }
//        } else {
//          Log("Failed to create photo message. Could not parse body into json string.")
//          completion(nil)
//        }
//      } else {
//        Log("Failed to create photo message. Tag name was too long.")
//        completion(nil)
//      }
//    }
//    
//    /**
//        Sends a POST request to the server creating a video message on the given tag (by name).
//     
//        - Note: Needs to receive a filled in `SkeletonMessage` model in response in order to give local stores the correct message id and such.
//     
//        - Parameters:
//            - user: The `GoogleUser` model filled with the information from the currently logged in Google account.
//            - tagName: The name of the requested tag. Should be 1 to 8 characters in length.
//            - videoKey: The key for the video in the AWS bucket. Will be included in the message body.
//            - completion: The handler called when the POST request is completed. Needs to accept an optional `SkeletonMessage` model.
//     */
//    public static func createMessageOnTagWith(name tagName: String, includingVidoeoKey videoKey: String, completion: @escaping (SkeletonMessage?) -> ()) {
//      if tagName.characters.count <= 8 {
//        if let messageBodyJSONString = Helper.encodeDictionaryIntoJSONString(dictionary: ["video_message": ["video_key": videoKey]]) {
//          if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "messages/create/") {
//            AuthenticatedNetworkAPI.POSTRequestWithDataResponseTo(url: url, with: ["tag_name": tagName, "message_body": messageBodyJSONString], completion: { (statusCode, responseDictionary) in
//              if let messageDictionary = responseDictionary?["message"] as? NSDictionary {
//                let messageModelsParsedFromDictionary = parseMessageModelsFrom(messageDictionaries: [messageDictionary])
//                if messageModelsParsedFromDictionary.count == 1 {
//                  Log("Successfully created video message and recieved a filled in message in response.")
//                  completion(messageModelsParsedFromDictionary[0])
//                } else {
//                  Log("Failed to create video message. More than one filled in message returned or messages dictionary parse failed.")
//                  completion(nil)
//                }
//              } else {
//                Log("Failed to create video message. No filled in message dictionaries returned.")
//                completion(nil)
//              }
//            })
//          } else {
//            Log("Failed to create video message. URL could not be created.")
//            completion(nil)
//          }
//        } else {
//          Log("Failed to create video message. Could not parse body into json string.")
//          completion(nil)
//        }
//      } else {
//        Log("Failed to create video message. Tag name was too long.")
//        completion(nil)
//      }
//    }
    
    /**
        Sends a GET request to the server asking for the most recent messages on a tag (by name).
     
        - Parameters:
            - name: The name of the tag which messages are requested from.
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `SkeletonMessage` models.
     */
    public static func latestMessagesFromTagWith(name tagName: String, completion: @escaping ([SkeletonMessage]?) -> ()) {
      if tagName.characters.count <= 8 {
        if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "messages/latest/", parameters: ["tagName": tagName]) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let messageDictionaries = responseDictionary?["messages"] as? [NSDictionary] {
              let messageModelsParsedFromDictionary = parseMessageModelsFrom(messageDictionaries: messageDictionaries)
              Log("Successfully grabbed and parsed latest messages in tag (\(tagName)).")
              completion(messageModelsParsedFromDictionary)
            } else {
              Log("Failed to get latest messages in tag (\(tagName)). No message dictionaries returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to get latest messages in tag (\(tagName)). URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to get latest messages in tag (\(tagName)). Tag name was too long.")
        completion(nil)
      }
    }
    
    /**
        Sends a GET request to the server asking for the single most recent message on a tag (by name).
     
        - Parameters:
            - name: The name of the tag which a message is requested from.
            - completion: The handler called when the GET request is completed. Needs to accept an optional `SkeletonMessage` model.
     */
    public static func lastMessageFromTagWith(name tagName: String, completion: @escaping (SkeletonMessage?) -> ()) {
      if tagName.characters.count <= 8 {
        if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "messages/last/", parameters: ["tagName": tagName]) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let messageDictionary = responseDictionary?["message"] as? NSDictionary {
              let messageModelsParsedFromDictionary = parseMessageModelsFrom(messageDictionaries: [messageDictionary])
              if messageModelsParsedFromDictionary.count == 1 {
                Log("Successfully grabbed and parsed the last message in tag (\(tagName)).")
                completion(messageModelsParsedFromDictionary[0])
              } else {
                Log("Failed to get last message. More than one filled in message returned or messages dictionary parse failed.")
                completion(nil)
              }
            } else {
              Log("Failed to get last message in tag (\(tagName)). No message dictionaries returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to get last message in tag (\(tagName)). URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to get last message in tag (\(tagName)). Tag name was too long.")
        completion(nil)
      }
    }
    
    /**
        Sends a GET request to the server asking for the messages before a given message (by id) on a tag (by name). Used to show older messages than the ones loaded initially.
     
        - Parameters:
            - name: The name of the tag which messages are requested from.
            - messageID: Identifier for the message that messages are requested before.
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `SkeletonMessage` models.
     */
    public static func messagesFromTagWith(name tagName: String, beforeMessageWithID messageID: Int, completion: @escaping ([SkeletonMessage]?) -> ()) {
      if tagName.characters.count <= 8 && messageID >= 0 {
        if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "messages/before/", parameters: ["tagName": tagName, "messageID": "\(messageID)"]) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let messageDictionaries = responseDictionary?["messages"] as? [NSDictionary] {
              let messageModelsParsedFromDictionary = parseMessageModelsFrom(messageDictionaries: messageDictionaries)
              Log("Successfully grabbed and parsed messages before message (\(messageID)) in tag (\(tagName)).")
              completion(messageModelsParsedFromDictionary)
            } else {
              Log("Failed to get messages before message (\(messageID)) in tag (\(tagName)). No message dictionaries returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to get messages before message (\(messageID)) in tag (\(tagName)). URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to get messages before message (\(messageID)) in tag (\(tagName)). Tag name was too long or invalid message id.")
        completion(nil)
      }
    }
    
//    /**
//        Sends a GET request to the server asking for the messages after a given message (by id) on a tag (by name). Used to show messages that were posted after the initial load.
//     
//        - Parameters:
//            - name: The name of the tag which messages are requested from.
//            - messageID: Identifier for the message that messages are requested after.
//            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `SkeletonMessage` models.
//     */
//    public static func messagesFromTagWith(name: String, afterMessageWithID messageID: Int, completion: @escaping ([SkeletonMessage]?) -> ()) {
//      
//      // Create the url for the request
//      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "messages/after/", parameters: ["tagName": name, "messageID": "\(messageID)"]) {
//        
//        // Send the GET request
//        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
//          
//          // Grab the message model dictionaries
//          if let messageDictionaries = responseDictionary?["messages"] as? [NSDictionary] {
//            
//            // Parse the individual message model dictionaries
//            let messageModelsParsedFromDictionary = parseMessageDictionariesIntoMessageObjects(messageDictionaries: messageDictionaries)
//            
//            // Pass it back
//            Log("Successfully grabbed and parsed messages before message (\(messageID)) in tag (\(name)).")
//            completion(messageModelsParsedFromDictionary)
//            
//          } else {
//            Log("Failed to get messages before message (\(messageID)) in tag (\(name)). No message dictionaries returned.")
//            completion(nil)
//          }
//          
//        })
//        
//      } else {
//        Log("Failed to get messages before message (\(messageID)) in tag (\(name)). URL could not be created.")
//        completion(nil)
//      }
//    }
    
    /**
        Sends a POST request to the server attempting to flag a message (by id).
     
        - Parameters:
            - id: The identifier for the message being flagged.
            - completion: The handler called when the GET request is completed. Needs to accept a boolean (true for success, false otherwise).
     */
    public static func flagMessageBy(id messageID: Int, completion: @escaping (Bool) -> ()) {
      if messageID >= 0 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "messages/flagMessage/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["message_id": messageID], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("Message (\(messageID)) flagged successfully.")
                completion(true)
              default:
                Log("Failed to flag message (\(messageID)) with status code: \(statusCode).")
                completion(false)
            }
          })
        } else {
          Log("Failed to flag message (\(messageID)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to flag message (\(messageID)). Invalid message id.")
        completion(false)
      }
    }
    
    /**
        Sends a POST request to the server attempting to unflag a message (by id).
     
        - Parameters:
            - id: The identifier for the message being unflagged.
            - completion: The handler called when the GET request is completed. Needs to accept a boolean (true for success, false otherwise).
     */
    public static func unflagMessageBy(id messageID: Int, completion: @escaping (Bool) -> ()) {
      if messageID >= 0 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "messages/unflagMessage/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["message_id": messageID], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
            case 201:
              Log("Message (\(messageID)) unflagged successfully.")
              completion(true)
            default:
              Log("Failed to unflagged message (\(messageID)) with status code: \(statusCode).")
              completion(false)
            }
          })
        } else {
          Log("Failed to unflagged message (\(messageID)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to unflagged message (\(messageID)). Invalid message id.")
        completion(false)
      }
    }
    
    /**
        Sends a GET request to the server asking for all flagged messages.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `SkeletonMessage` models.
     */
    public static func flaggedMessages(completion: @escaping ([SkeletonMessage]?) -> ()) {
      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "messages/flagged/", parameters: nil) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let messageDictionaries = responseDictionary?["messages"] as? [NSDictionary] {
            let messageModels = parseMessageModelsFrom(messageDictionaries: messageDictionaries)
            Log("Successfully grabbed and parsed flagged messages.")
            completion(messageModels)
          } else {
            Log("Failed to get flagged messages. No message dictionaries returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get flagged messages. URL could not be created.")
        completion(nil)
      }
    }
    
    /**
        Parses an array of message dictionaries into an array of `SkeletonMessage` models.
     
        - Note: Any message without a formatted body won't be parsed.
     
        - Parameters:
            - messageDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `SkeletonMessage` model and extra info for a custom message model.
     
        - Returns: An array of `SkeletonMessage` models.
     */
    static func parseMessageModelsFrom(messageDictionaries: [NSDictionary]) -> [SkeletonMessage] {
      var messagesArray = [SkeletonMessage]()
      for messageDict in messageDictionaries {
        let message = SkeletonMessage() // Parse the basic info that every type of message contains
        if let messageID = messageDict["message_id"] as? Int {
          message.messageID = messageID
        }
        if let tagName = messageDict["tag_name"] as? String {
          message.tagName = tagName
        }
        if let postDateString = messageDict["post_date"] as? String {
          if let dateParsedFromPostDateString = Helper.dateFromMySQLTimestamp(formattedString: postDateString) {
            message.postDate = dateParsedFromPostDateString
          }
        }
        if let postCreatorID = messageDict["post_creator_id"] as? Int {
          message.postCreatorID = postCreatorID
        }
        if let firstName = messageDict["first_name"] as? String {
          if let lastName = messageDict["last_name"] as? String {
            message.postCreatorName = "\(firstName) \(lastName)"
          }
        }
        if let messageBodyString = messageDict["message"] as? String, let messageBodyDictionary = Helper.decodeJSONStringIntoDictionary(jsonString: messageBodyString) {
          if let messageWithParsedBody = parseMessageBodyFrom(messageBodyDictionary: messageBodyDictionary, usingBasicInfoFrom: message) { // Parse the message body
            messagesArray.append(messageWithParsedBody)
          }
        }
      }
      
      return messagesArray
    }
    
    /**
        Parses a dictionary containing the message body info to grab the key information that makes it conform to one of the custom message types like `PureMessage` or `PhotoMessage`. If the dictionary does not contain information from one of the custom types, nil is returned.
     
        - Parameters:
            - messageBodyDictionary: The dictionary that contains info needed to fill out one of the custom message types.
            - skeletonMessage: The basic message used to initialize the custom type. This should contain information like post date and creator name.
     
        - Returns: An optional `SkeletonMessage` model.
     */
    static func parseMessageBodyFrom(messageBodyDictionary: NSDictionary, usingBasicInfoFrom skeletonMessage: SkeletonMessage) -> SkeletonMessage? {
      if let pureMessageDictionary = messageBodyDictionary["pure_message"] as? NSDictionary {
        let pureMessage = PureMessage(skeletonMessage: skeletonMessage)
        if let messageText = pureMessageDictionary["text"] as? String {
          pureMessage.message = messageText
        }
        
        return pureMessage
      } else if let photoMessageDictionary = messageBodyDictionary["photo_message"] as? NSDictionary {
        let photoMessage = PhotoMessage(skeletonMessage: skeletonMessage)
        if let photoKey = photoMessageDictionary["photo_key"] as? String {
          photoMessage.photoKey = photoKey
        }
        
        return photoMessage
      } else if let videoMessageDictionary = messageBodyDictionary["video_message"] as? NSDictionary {
        let videoMessage = VideoMessage(skeletonMessage: skeletonMessage)
        if let videoKey = videoMessageDictionary["video_key"] as? String {
          videoMessage.videoKey = videoKey
        }
        
        return videoMessage
      }
      
      return nil
    }
    
    //      else if let sportsScheduleMessageDictionary = messageBodyDictionary["sports_schedule_message"] as? NSDictionary { // Sports schedule message
    //
    //        let sportsScheduleMessage = SportsScheduleMessage(skeletonMessage: message) //new message with all the already parsed data
    //        if let opponentName = sportsScheduleMessageDictionary["opponent_name"] as? String {
    //          sportsScheduleMessage.opponentName = opponentName
    //        }
    //        if let location = sportsScheduleMessageDictionary["location"] as? String {
    //          sportsScheduleMessage.location = location
    //        }
    //        if let eventDateString = sportsScheduleMessageDictionary["event_date"] as? String {
    //          if let dateParsedFromEventDateString = Helper.dateFromMySQLTimestamp(formattedString: eventDateString) {
    //            sportsScheduleMessage.postDate = dateParsedFromEventDateString
    //          }
    //        }
    //        if let sportName = sportsScheduleMessageDictionary["sport_name"] as? String {
    //          sportsScheduleMessage.sport = sportName
    //        }
    //        messagesArray.append(sportsScheduleMessage)
    //
    //      } else if let sportsScheduleMessageDictionary = messageBodyDictionary["sports_result_message"] as? NSDictionary { // Sports result message
    //
    //        let sportsResultMessage = SportsResultMessage(skeletonMessage: message) //new message with all the already parsed data
    //        if let opponentName = sportsScheduleMessageDictionary["opponent_name"] as? String {
    //          sportsResultMessage.opponentName = opponentName
    //        }
    //        if let opponentScoreString = sportsScheduleMessageDictionary["opponent_score"] as? String {
    //          if let opponentScore = Int(opponentScoreString) {
    //            sportsResultMessage.opponentScore = opponentScore
    //          }
    //        }
    //        if let homeScoreString = sportsScheduleMessageDictionary["home_score"] as? String {
    //          if let homeScore = Int(homeScoreString) {
    //            sportsResultMessage.homeScore = homeScore
    //          }
    //        }
    //        if let sportName = sportsScheduleMessageDictionary["sport_name"] as? String {
    //          sportsResultMessage.sport = sportName
    //        }
    //        messagesArray.append(sportsResultMessage)
    //        
    //      }
    
//    /**
//        Parses a Date object into a string (format: "h:mm a 'on' E, MMM d") for display on the message/tag preview custom table view cells.
//     
//        - Parameters:
//            - date: A date object used to create the formatted string.
//     
//        - Returns: A formatted String.
//     */
//    public static func formattedStringFrom(date: Date) -> String {
//      
//      // Setup the date formatter
//      let dateFormatter = DateFormatter()
//      dateFormatter.dateFormat =
//      
//      // Create a formatted string
//      let formattedStringFromDate = dateFormatter.string(from: date)
//      
//      // Return the result
//      return formattedStringFromDate
//    }
  
    //"h:mm a 'on' E, MMM d"
  }
  
  
  /// The API category for calls used to download event information and check in the user.
  struct Events {
    
    /**
        Sends a POST request to the server creating an event.
     
        - Note: Needs to receive a filled in `Event` model in response.
     
        - Parameters:
            - name: The name of the new event.
            - checkInPoints: The number of points that the user gains by checking into the event.
            - startDate: The start date of the event.
            - startDate: The event date of the event.
            - locationName: The name of the location of the event.
            - locationAddress: The address of the event location.
            - locationLatitude: The longitude of the center of the area where the user must be to check in.
            - locationLongitude: The latitude of the center of the area where the user must be to check in.
            - completion: The handler called when the POST request is completed. Needs to accept an optional `Event` model.
     */
    public static func createEventWith(name: String, checkInPoints: Int, startDate: Date, endDate: Date, locationName: String, locationAddress: String, locationLatitude: Double, locationLongitude: Double, completion: @escaping (Event?) -> ()) {
      if name.characters.count <= 256 && checkInPoints > 0 && checkInPoints <= 100 && locationName.characters.count <= 32 && locationAddress.characters.count <= 256 && locationLatitude >= -90 && locationLatitude <= 90 && locationLongitude >= -180 && locationLongitude <= 180 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "events/create/") {
          var requestBody = [String: Any]()
          requestBody["event_name"] = name
          requestBody["leaderboard_points"] = checkInPoints
          requestBody["start_date"] = Helper.MySQLTimestampFormattedStringFrom(date: startDate)
          requestBody["end_date"] = Helper.MySQLTimestampFormattedStringFrom(date: endDate)
          requestBody["location_name"] = locationName
          requestBody["location_address"] = locationAddress
          requestBody["location_latitude"] = locationLatitude
          requestBody["location_longitude"] = locationLongitude
          AuthenticatedNetworkAPI.POSTRequestWithDataResponseTo(url: url, with: requestBody, shouldRefreshAuthIfExpired: true, completion: { (statusCode, responseDictionary) in
            if let eventDictionary = responseDictionary?["event"] as? NSDictionary {
              let eventModelsParsedFromDictionary = parseEventModelsFrom(eventDictionaries: [eventDictionary])
              if eventModelsParsedFromDictionary.count == 1 {
                Log("Successfully created event and received filled in model back.")
                completion(eventModelsParsedFromDictionary[0])
              } else {
                Log("Failed to create event. More than one filled in event returned or events dictionary parse failed.")
                completion(nil)
              }
            } else {
              Log("Failed to create event. No event dictionary returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to create event. URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to create event. At least one piece of datat was an invalid length.")
        completion(nil)
      }
    }

    /**
        Sends a GET request to the server asking for all future events.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `Event` models.
     */
    public static func getFutureEvents(completion: @escaping ([Event]?) -> ()) {
      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "events/future/", parameters: nil) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let eventDictionaries = responseDictionary?["events"] as? [NSDictionary] {
            let eventModelsParsedFromDictionary = parseEventModelsFrom(eventDictionaries: eventDictionaries)
            Log("Successfully grabbed and parsed future events.")
            completion(eventModelsParsedFromDictionary)
          } else {
            Log("Failed to get future events. No event dictionaries returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get future events. URL could not be created.")
        completion(nil)
      }
    }
    
    /**
        Sends a POST request to the server attempting to check the user into the given event.
     
        - Parameters:
            - eventID: The server's identifier for the event that the client wants to check in to.
            - graduationYear: The year that the checked in user will graduate (self-selected).
            - completion: The handler called when the POST request is completed. Needs to accept a boolean value with true for success or false for error.
     */
    public static func checkInToEventWith(id eventID: Int, forGraduationYear graduationYear: Int, completion: @escaping (Bool) -> ()) {
      if eventID >= 0 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "events/checkIn/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["event_id": eventID, "graduation_year": graduationYear], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("Successfully checked in user to event (\(eventID)) for graduation year (\(graduationYear)).")
                completion(true)
              default:
                Log("Failed to check in user to event (\(eventID)) for graduation year (\(graduationYear)). Returned status code: \(statusCode).")
                completion(false)
            }
          })
        } else {
          Log("Failed to check in user to event (\(eventID)) for graduation year (\(graduationYear)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to check in user to event (\(eventID)) for graduation year (\(graduationYear)). Invalid eventID.")
        completion(false)
      }
    }
    
    /**
        Sends a GET request to the server to see if the user has checked into the given event.
     
        - Parameters:
            - eventID: The server's identifier for the event that the client may or may not be checked into.
            - completion: The handler called when the GET request is completed. Needs to accept a boolean value with true for already checked in or false for not/error.
     */
    public static func checkInStatusToEventWith(id eventID: Int, completion: @escaping (Bool) -> ()) {
      if eventID >= 0 {
        if let url = AuthenticatedNetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "events/checkInStatus/", parameters: ["eventID": "\(eventID)"], shouldRefreshAuthIfExpired: true) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let userCheckedIn = responseDictionary?["checked_in"] as? Bool {
              if userCheckedIn {
                Log("User is already checked in to event (\(eventID)).")
                completion(true)
              } else {
                Log("User is not yet checked in to event (\(eventID)).")
                completion(false)
              }
            } else {
              Log("Failed to get user check in status to event (\(eventID)). No checked in boolean was returned.")
              completion(false)
            }
          })
        } else {
          Log("Failed to get user check in status to event (\(eventID)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to get user check in status to event (\(eventID)). Invalid eventID.")
        completion(false)
      }
    }
    
    /**
        Sends a GET request to the server asking for a list of names of every user checked into the given event.
    
        - Parameters:
            - eventID: The server's identifier for the requested event.
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of string names.
    */
    public static func getCheckedInUserListFor(eventID: Int, completion: @escaping ([String]?) -> ()) {
      if eventID >= 0 {
        if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "events/checkedInUsernameList/", parameters: ["eventID": "\(eventID)"]) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let checkedInUserList = responseDictionary?["checked_in_usernames"] as? [String] {
              Log("Successfully grabbed and parsed list of checked in users.")
              completion(checkedInUserList)
            } else {
              Log("Failed to get list of checked in users. No usernames dictionaries returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to get list of checked in users. URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to get list of checked in users. Invalid eventID.")
        completion(nil)
      }
    }
    
    /**
        Parses an array of event dictionaries into an array of `Event` models.
     
        - Parameters:
            - eventDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `Event` model.
        - Returns: An array of `Event` models.
     */
    private static func parseEventModelsFrom(eventDictionaries: [NSDictionary]) -> [Event] {
      var eventsArray = [Event]()
      for eventDict in eventDictionaries {
        var event = Event()
        if let eventID = eventDict["event_id"] as? Int {
          event.eventID = eventID
        }
        if let eventName = eventDict["event_name"] as? String {
          event.eventName = eventName
        }
        if let startDateString = eventDict["start_date"] as? String {
          if let dateParsedFromStartDateString = Helper.dateFromMySQLTimestamp(formattedString: startDateString) {
            event.startDate = dateParsedFromStartDateString
          }
        }
        if let endDateString = eventDict["end_date"] as? String {
          if let dateParsedFromEndDateString = Helper.dateFromMySQLTimestamp(formattedString: endDateString) {
            event.endDate = dateParsedFromEndDateString
          }
        }
        if let locationName = eventDict["location_name"] as? String {
          event.locationName = locationName
        }
        if let locationAddress = eventDict["location_address"] as? String {
          event.locationAddress = locationAddress
        }
        if let locationLongitude = eventDict["location_longitude"] as? Double {
          event.locationLongitude = locationLongitude
        }
        if let locationLatitude = eventDict["location_latitude"] as? Double {
          event.locationLatitude = locationLatitude
        }
        if let leaderboardPoints = eventDict["leaderboard_points"] as? Int {
          event.leaderboardPoints = leaderboardPoints
        }
        eventsArray.append(event)
      }
      
      return eventsArray
    }
  }
  
  /// The API category for calls used to download sports information.
  struct Sports {
    
    /**
        Sends a GET request to the server asking for all scheduled games for the given sport.
     
        - Parameters:
            - sportName: The name of sport to grab info for.
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `ScheduledSportsGame` models.
     */
    public static func getScheduledGamesForSportWith(name sportName: String, completion: @escaping ([ScheduledSportsGame]?) -> ()) {
      if sportName.characters.count <= 64 {
        if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "sports/scheduledGames/", parameters: ["sportName": sportName]) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let scheduledGameDictionaries = responseDictionary?["schedules_games"] as? [NSDictionary] {
              let scheduledGameModelsFromDictionary = parseScheduledGameModelsFrom(scheduledGameDictionaries: scheduledGameDictionaries)
              Log("Successfully grabbed and parsed scheduled games for \(sportName).")
              completion(scheduledGameModelsFromDictionary)
            } else {
              Log("Failed to get scheduled games for \(sportName). No scheduled game dictionaries returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to get scheduled games for \(sportName). URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to get scheduled games for \(sportName). Sport name too long.")
        completion(nil)
      }
    }
    
    /**
        Sends a GET request to the server asking for all game results for the given sport.
     
        - Parameters:
            - sportName: The name of sport to grab info for.
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `SportsGameResult` models.
     */
    public static func getGameResultsForSportWith(name sportName: String, completion: @escaping ([SportsGameResult]?) -> ()) {
      if sportName.characters.count <= 64 {
        if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "sports/gameResults/", parameters: ["sportName": sportName]) {
          NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
            if let gameResultDictionaries = responseDictionary?["game_results"] as? [NSDictionary] {
              let gameResultModelsFromDictionary = parseGameResultModelsFrom(gameResultDictionaries: gameResultDictionaries)
              Log("Successfully grabbed and parsed game results for \(sportName).")
              completion(gameResultModelsFromDictionary)
            } else {
              Log("Failed to get game results for \(sportName). No game results dictionaries returned.")
              completion(nil)
            }
          })
        } else {
          Log("Failed to get game results for \(sportName). URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to get game results for \(sportName). Sport name too long.")
        completion(nil)
      }
    }
    
    /**
        Parses an array of scheduled game dictionaries into an array of `ScheduledSportsGame` models.
     
        - Parameters:
            - scheduledGameDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `ScheduledSportsGame` model.
        - Returns: An array of `ScheduledSportsGame` models.
     */
    private static func parseScheduledGameModelsFrom(scheduledGameDictionaries: [NSDictionary]) -> [ScheduledSportsGame] {
      var scheduledGamesArray = [ScheduledSportsGame]()
      for scheduledGameDict in scheduledGameDictionaries {
        var scheduledGame = ScheduledSportsGame()
        if let sportName = scheduledGameDict["sport_name"] as? String {
          scheduledGame.sportName = sportName
        }
        if let gameDateString = scheduledGameDict["game_date"] as? String {
          if let dateParsedFromGameDateString = Helper.dateFromMySQLTimestamp(formattedString: gameDateString) {
            scheduledGame.date = dateParsedFromGameDateString
          }
        }
        if let opponentName = scheduledGameDict["opponent_name"] as? String {
          scheduledGame.opponentName = opponentName
        }
        if let locationName = scheduledGameDict["location_name"] as? String {
          scheduledGame.locationName = locationName
        }
        scheduledGamesArray.append(scheduledGame)
      }
      
      return scheduledGamesArray
    }
    
    /**
        Parses an array of game result dictionaries into an array of `SportsGameResult` models.
     
        - Parameters:
            - scheduledGameDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `SportsGameResult` model.
        - Returns: An array of `SportsGameResult` models.
     */
    private static func parseGameResultModelsFrom(gameResultDictionaries: [NSDictionary]) -> [SportsGameResult] {
      var gameResultsArray = [SportsGameResult]()
      for gameResultDict in gameResultDictionaries {
        var gameResult = SportsGameResult()
        if let sportName = gameResultDict["sport_name"] as? String {
          gameResult.sportName = sportName
        }
        if let gameDateString = gameResultDict["game_date"] as? String {
          if let dateParsedFromGameDateString = Helper.dateFromMySQLTimestamp(formattedString: gameDateString) {
            gameResult.date = dateParsedFromGameDateString
          }
        }
        if let opponentName = gameResultDict["opponent_name"] as? String {
          gameResult.opponentName = opponentName
        }
        if let opponentScore = gameResultDict["opponent_score"] as? Int {
          gameResult.opponentScore = opponentScore
        }
        if let homeScore = gameResultDict["home_score"] as? Int {
          gameResult.homeScore = homeScore
        }
        gameResultsArray.append(gameResult)
      }
      
      return gameResultsArray
    }
    
  }
  
  /// The API category for calls used hide or show messages, tags, etc.
  struct Moderators {
    
    /**
        Sends a POST request to the server attempting to hide a message (by id).
     
        - Parameters:
            - id: The identifier for the message being hidden.
            - completion: The handler called when the POST request is completed. Needs to accept a boolean (true for success, false otherwise).
     */
    public static func hideMessageBy(id messageID: Int, completion: @escaping (Bool) -> ()) {
      if messageID >= 0 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "moderator/hideMessage/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["message_id": messageID], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("Message (\(messageID)) hidden successfully.")
                completion(true)
              default:
                Log("Failed to hide message (\(messageID)) with status code: \(statusCode).")
                completion(false)
            }
          })
        } else {
          Log("Failed to hide message (\(messageID)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to hide message (\(messageID)). Invalid messageID.")
        completion(false)
      }
    }
    
    /**
        Sends a POST request to the server attempting to hide a tag (by name).
     
        - Parameters:
            - name: The name of the tag being hidden.
            - completion: The handler called when the POST request is completed. Needs to accept a boolean (true for success, false otherwise).
     */
    public static func hideTagBy(name tagName: String, completion: @escaping (Bool) -> ()) {
      if tagName.characters.count <= 8 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "moderator/hideTag/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["tag_name": tagName], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("Tag (\(tagName)) hidden successfully.")
                completion(true)
              default:
                Log("Failed to hide tag (\(tagName)) with status code: \(statusCode).")
                completion(false)
            }
          })
        } else {
          Log("Failed to hide tag (\(tagName)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to hide tag (\(tagName)). Tag name was too long.")
        completion(false)
      }
    }
    
    /**
        Sends a POST request to the server attempting to delete a club (by id).
     
        - Parameters:
            - id: The server's identifier for the club being deleted.
            - completion: The handler called when the POST request is completed. Needs to accept a boolean (true for success, false otherwise).
     */
    public static func deleteClubBy(id: Int, completion: @escaping (Bool) -> ()) {
      if id > 0 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "moderator/deleteClub/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["club_id": id], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
            case 201:
              Log("Club (\(id)) deleted successfully.")
              completion(true)
            default:
              Log("Failed to delete club (\(id)) with status code: \(statusCode).")
              completion(false)
            }
          })
        } else {
          Log("Failed to delete club (\(id)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to delete club (\(id)). Id was invalid.")
        completion(false)
      }
    }
    
    /**
        Sends a POST request to the server attempting to hide a fan cam image record (by id).
     
        - Parameters:
            - id: The identifier for the fan cam image record being hidden.
            - completion: The handler called when the POST request is completed. Needs to accept a boolean (true for success, false otherwise).
     */
    public static func hideFanCamImageRecordBy(id recordID: Int, completion: @escaping (Bool) -> ()) {
      if recordID >= 0 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "moderator/hideFanCamImageRecord/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["fan_cam_image_record_id": recordID], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
            case 201:
              Log("Fan cam image record (\(recordID)) hidden successfully.")
              completion(true)
            default:
              Log("Failed to hide fan cam image record (\(recordID)) with status code: \(statusCode).")
              completion(false)
            }
          })
        } else {
          Log("Failed to hide fan cam image record (\(recordID)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to hide fan cam image record (\(recordID)). Invalid recordID.")
        completion(false)
      }
    }
    
    /**
        Sends a POST request to the server attempting to clear all leaderboard scores.
     
        - Parameters:
            - completion: The handler called when the POST request is completed. Needs to accept a boolean (true for success, false otherwise).
     */
    public static func clearLeaderboardScores(completion: @escaping (Bool) -> ()) {
      if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "moderator/clearLeaderboardScores/") {
        AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: [:], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
          switch statusCode {
          case 201:
            Log("Leaderboard scores cleared successfully.")
            completion(true)
          default:
            Log("Failed to clear leaderboard scores with status code: \(statusCode).")
            completion(false)
          }
        })
      } else {
        Log("Failed to clear leaderboard scores. URL could not be created.")
        completion(false)
      }
    }
  }
  
  /// The API category for calls used to manage moderators.
  struct Admins {
    
    /**
        Sends a GET request to the server asking for information about each moderator.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `Moderator` models.
     */
    public static func getAllModerators(completion: @escaping ([Moderator]?) -> ()) {
      if let url = AuthenticatedNetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "admin/allModerators/", parameters: nil, shouldRefreshAuthIfExpired: true) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let moderatorDictionaries = responseDictionary?["moderators"] as? [NSDictionary] {
            let moderatorModelsParsedFromDictionary = parseModeratorModelsFrom(moderatorDictionaries: moderatorDictionaries)
            Log("Successfully grabbed and parsed information about each moderator.")
            completion(moderatorModelsParsedFromDictionary)
          } else {
            Log("Failed to get information about each moderator. No moderator dictionaries returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get information about each moderator. URL could not be created.")
        completion(nil)
      }
    }
    
    /**
        Sends a POST request to the server attempting to demote a moderator (by id).
     
        - Parameters:
            - id: The identifier for the moderator being demoted.
            - completion: The handler called when the GET request is completed. Needs to accept a boolean (true for success, false otherwise).
     */
    public static func demoteModeratorBy(id moderatorID: Int, completion: @escaping (Bool) -> ()) {
      if moderatorID >= 0 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "admin/demoteModerator/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["moderator_id": moderatorID], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("Moderator (\(moderatorID)) demoted successfully.")
                completion(true)
              default:
                Log("Failed to demote moderator (\(moderatorID)) with status code: \(statusCode).")
                completion(false)
            }
          })
        } else {
          Log("Failed to demote moderator (\(moderatorID)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to demote moderator (\(moderatorID)). Invalid moderatorID.")
        completion(false)
      }
    }
    
    /**
        Sends a POST request to the server attempting to promote a user (by email) to moderator status.
     
        - Parameters:
            - email: The email address of the user being promoted.
            - completion: The handler called when the GET request is completed. Needs to accept a boolean (true for success, false otherwise).
     */
    public static func promoteUserBy(email: String, completion: @escaping (Bool) -> ()) {
      if email.characters.count <= 50 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "admin/promoteUser/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["email": email], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("User (\(email)) promoted successfully.")
                completion(true)
              default:
                Log("Failed to promoted user (\(email)) with status code: \(statusCode).")
                completion(false)
            }
          })
        } else {
          Log("Failed to promoted user (\(email)). URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to promoted user (\(email)). Email was too long.")
        completion(false)
      }
    }
    
    /**
        Parses an array of moderator dictionaries into an array of `Moderator` models.
     
        - Parameters:
            - moderatorDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `Moderator` model.
        - Returns: An array of `Moderator` models.
     */
    private static func parseModeratorModelsFrom(moderatorDictionaries: [NSDictionary]) -> [Moderator] {
      var moderatorArray = [Moderator]()
      for moderatorDict in moderatorDictionaries {
        var moderator = Moderator()
        if let moderatorID = moderatorDict["user_id"] as? Int {
          moderator.moderatorID = moderatorID
        }
        if let firstName = moderatorDict["first_name"] as? String {
          if let lastName = moderatorDict["last_name"] as? String {
            moderator.name = firstName + " " + lastName
          }
        }
        if let email = moderatorDict["email"] as? String {
          moderator.email = email
        }
        moderatorArray.append(moderator)
      }
      
      return moderatorArray
    }
  }
  
  /// The API category for calls used to upload and download information about images posted in the fan cam section.
  struct FanCam {
    
    /**
        Sends a POST request to the server attempting to create a fan cam image record.
     
        - Parameters:
            - awsKey: The unique key of the uploaded image on AWS S3.
            - completion: The handler called when the POST request is completed. Needs to accept bool that is true if success, else false.
     */
    public static func createFanCamImageRecordWith(awsKey: String, completion: @escaping (Bool) -> ()) {
      if awsKey.characters.count >= 0 {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "fancam/create/") {
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: ["image_aws_key": awsKey], shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
              case 201:
                Log("Created fan cam image record successfully.")
                completion(true)
              default:
                Log("Failed to create fan cam image record with status code: \(statusCode).")
                completion(false)
            }
          })
        } else {
          Log("Failed to create fan cam image record. URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to create fan cam image record. Invalid aws key.")
        completion(false)
      }
    }
    
    /**
        Sends a GET request to the server asking for all fan cam images.
     
        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `FanCamImageRecord` models.
     */
    public static func getFanCamImageRecords(completion: @escaping ([FanCamImageRecord]?) -> ()) {
      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "fancam/all/", parameters: nil) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let fanCamImageDictionaries = responseDictionary?["fan_cam_records"] as? [NSDictionary] {
            let famCamImageModelsParsedFromDictionary = parseFanCamImageModelsFrom(fanCamImageDictionaries: fanCamImageDictionaries)
            Log("Successfully grabbed and parsed fan cam image records.")
            completion(famCamImageModelsParsedFromDictionary)
          } else {
            Log("Failed to get fan cam image records. No fan cam image record dictionaries returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get fan cam image records. URL could not be created.")
        completion(nil)
      }
    }
    
    /**
        Parses an array of fan cam image record dictionaries into an array of `FanCamImageRecord` models.
     
        - Parameters:
            - fanCamImageDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `FanCamImageRecord` model.
        - Returns: An array of `FanCamImageRecord` models.
     */
    private static func parseFanCamImageModelsFrom(fanCamImageDictionaries: [NSDictionary]) -> [FanCamImageRecord] {
      var fanCamImageArray = [FanCamImageRecord]()
      for fanCamImageDict in fanCamImageDictionaries {
        var imageRecord = FanCamImageRecord()
        if let fanCamImageID = fanCamImageDict["record_id"] as? Int {
          imageRecord.recordID = fanCamImageID
        }
        if let imageAWSKey = fanCamImageDict["image_aws_key"] as? String {
          imageRecord.imageAWSKey = imageAWSKey
        }
        fanCamImageArray.append(imageRecord)
      }
      
      return fanCamImageArray
    }
  }
  
  /// The API category for calls used to create and get info about clubs.
  struct Clubs {
    
    /**
        Sends a POST request to the server attempting to create a club.
     
        - Parameters:
            - name: The name of the club.
            - associatedTagName: The name of the linked tag.
            - clubLeaders: The name of each of the club leaders.
            - meetingDays: The names of the days of the week that the club meets.
            - meetingTime: The time of day that the club meets.
            - meetingLocation: The name of the location that the club meets.
            - completion: The handler called when the POST request is completed. Needs to accept an optional `Club` model.
     */
    public static func createClubWith(name: String, associatedTagName: String, clubLeaders: [String], meetingDays: [String], meetingTime: String, meetingLocation: String, completion: @escaping (Club?) -> ()) {
      if !name.isEmpty && !associatedTagName.isEmpty && associatedTagName.characters.count <= 8 && clubLeaders.count > 0 && meetingDays.count > 0 && !meetingTime.isEmpty && !meetingLocation.isEmpty {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "clubs/create/") {
          var requestBody = [String: Any]()
          requestBody["club_name"] = name
          requestBody["associated_tag_name"] = associatedTagName
          requestBody["club_leaders"] = clubLeaders
          requestBody["meeting_days"] = meetingDays
          requestBody["meeting_time"] = meetingTime
          requestBody["meeting_location"] = meetingLocation
          AuthenticatedNetworkAPI.POSTRequestWithDataResponseTo(url: url, with: requestBody, shouldRefreshAuthIfExpired: true, completion: { (statusCode, responseDictionary) in
            if let clubDictionary = responseDictionary?["club"] as? NSDictionary {
              let clubModelsParsedFromDictionary = parseClubModelsFrom(clubDictionaries: [clubDictionary])
              if clubModelsParsedFromDictionary.count == 1 {
                Log("Successfully created club and received filled in model back.")
                completion(clubModelsParsedFromDictionary[0])
              } else {
                Log("Failed to create club. More than one filled in club returned or club dictionary parse failed.")
                completion(nil)
              }
            }
          })
        } else {
          Log("Failed to create club. URL could not be created.")
          completion(nil)
        }
      } else {
        Log("Failed to create club. At least one piece of input was invalid.")
        completion(nil)
      }
    }
    
    /**
        Sends a POST request to the server attempting to update a club.
     
        - Parameters:
            - id: The server's identifier for the club.
            - name: The name of the club.
            - associatedTagName: The name of the linked tag.
            - clubLeaders: The name of each of the club leaders.
            - meetingDays: The names of the days of the week that the club meets.
            - meetingTime: The time of day that the club meets.
            - meetingLocation: The name of the location that the club meets.
            - completion: The handler called when the POST request is completed. Needs to boolean that is true on success, false otherwise.
     */
    public static func updateClubWith(id: Int, name: String, associatedTagName: String, clubLeaders: [String], meetingDays: [String], meetingTime: String, meetingLocation: String, completion: @escaping (Bool) -> ()) {
      if id > 0 && !name.isEmpty && !associatedTagName.isEmpty && associatedTagName.characters.count <= 8 && clubLeaders.count > 0 && meetingDays.count > 0 && !meetingTime.isEmpty && !meetingLocation.isEmpty {
        if let url = NetworkAPI.makePOSTURLToBasePathWith(pathAddition: "clubs/update/") {
          var requestBody = [String: Any]()
          requestBody["club_id"] = id
          requestBody["club_name"] = name
          requestBody["associated_tag_name"] = associatedTagName
          requestBody["club_leaders"] = clubLeaders
          requestBody["meeting_days"] = meetingDays
          requestBody["meeting_time"] = meetingTime
          requestBody["meeting_location"] = meetingLocation
          AuthenticatedNetworkAPI.POSTRequestTo(url: url, with: requestBody, shouldRefreshAuthIfExpired: true, completion: { (statusCode) in
            switch statusCode {
            case 201:
              Log("Update club successfully.")
              completion(true)
            default:
              Log("Failed to update club with status code: \(statusCode).")
              completion(false)
            }
          })
        } else {
          Log("Failed to update club. URL could not be created.")
          completion(false)
        }
      } else {
        Log("Failed to update club. At least one piece of input was invalid.")
        completion(false)
      }
    }
    
    /**
        Sends a GET request to the server asking for all clubs.

        - Parameters:
            - completion: The handler called when the GET request is completed. Needs to accept an optional array of `Club` models.
     */
    public static func getAllClubs(completion: @escaping ([Club]?)->()) {
      if let url = NetworkAPI.makeGETQueryURLToBasePathWith(pathAddition: "clubs/all/", parameters: nil) {
        NetworkAPI.GETRequestTo(url: url, completion: { (responseDictionary) in
          if let clubDictionaries = responseDictionary?["clubs"] as? [NSDictionary] {
            let clubModelsParsedFromDictionary = parseClubModelsFrom(clubDictionaries: clubDictionaries)
            Log("Successfully grabbed and parsed all clubs.")
            completion(clubModelsParsedFromDictionary)
          } else {
            Log("Failed to get all clubs. No club dictionaries returned.")
            completion(nil)
          }
        })
      } else {
        Log("Failed to get all clubs. URL could not be created.")
        completion(nil)
      }
    }
    
    /**
        Parses an array of club dictionaries into an array of `Club` models.
     
        - Parameters:
            - clubDictionaries: An array of dictionaries that should contain all of the info needed to fill out a `Club` model.
        - Returns: An array of `Club` models.
     */
    private static func parseClubModelsFrom(clubDictionaries: [NSDictionary]) -> [Club] {
      var clubArray = [Club]()
      for clubDict in clubDictionaries {
        var club = Club()
        if let clubID = clubDict["club_id"] as? Int {
          club.clubID = clubID
        }
        if let clubName = clubDict["club_name"] as? String {
          club.clubName = clubName
        }
        if let associatedTagName = clubDict["associated_tag_name"] as? String {
          club.associatedTagName = associatedTagName
        }
        if let clubLeaders = clubDict["club_leaders"] as? [String] {
          club.clubLeaders = clubLeaders
        }
        if let meetingDays = clubDict["meeting_days"] as? [String] {
          club.meetingDays = meetingDays
        }
        if let meetingTime = clubDict["meeting_time"] as? String {
          club.meetingTime = meetingTime
        }
        if let meetingLocation = clubDict["meeting_location"] as? String {
          club.meetingLocation = meetingLocation
        }
        clubArray.append(club)
      }
      
      return clubArray
    }
  }
}

