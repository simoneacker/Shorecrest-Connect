//
//  GoogleCalendarManager.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/15/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/**
    Manages creating calendar events.
 */
class GoogleCalendarManager: NSObject {

  /// The Google Account access token used for accessing the calendar api.
  public var accessToken: String?
  
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
    var eventBodyDict = [String: Any]()
    eventBodyDict["start"] = ["dateTime" : Helper.iso8601FormattedStringFrom(date: startDate)]
    eventBodyDict["end"] = ["dateTime": Helper.iso8601FormattedStringFrom(date: endDate)]
    eventBodyDict["summary"] = eventTitle
    eventBodyDict["description"] = eventDescription
    
    if let accessToken = accessToken {
      if let url = URL(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events?access_token=\(accessToken)") {
        NetworkAPI.POSTRequestTo(url: url, with: eventBodyDict, completion: { (statusCode) in
          switch statusCode {
          case 200:
            Log("Successfully created event (\(eventTitle)).")
            completion?(true)
          default:
            Log("Failed to create event (\(eventTitle)) with status code: \(statusCode).")
            completion?(false)
          }
        })
      } else {
        Log("Failed to create event (\(eventTitle)). URL could not be created.")
        completion?(false)
      }
    } else {
      Log("Failed to create event (\(eventTitle)). Access token invalid.")
      completion?(false)
    }
  }
}
