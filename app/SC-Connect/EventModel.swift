//
//  EventModel.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 3/29/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/// Model for holding data about an event.
struct Event {
  
  /// Identifier of the event as given by the server.
  var eventID: Int = -1
  
  /// The text name for the event.
  var eventName: String = ""
  
  /// The starting date/time of the event.
  var startDate: Date = Date()
  
  /// The end date/time of the event.
  var endDate: Date = Date()
  
  /// The name of the location of the event.
  var locationName: String = ""
  
  /// The address of the location of the event.
  var locationAddress: String = ""
  
  /// The latitude of the event location as a decimal (between -90.0 and 90.0).
  var locationLatitude: Double = 0.0
  
  /// The longitude of the event location as a decimal (between -180.0 and 180.0).
  var locationLongitude: Double = 0.0
  
  /// The number of points the user gains on the leaderboard when they check into the event.
  var leaderboardPoints: Int = -1
  
  /// Stores if the sign in user is checked in to this event once it has been downloaded from the server.
  var userCheckedIn: Bool?
  
}
