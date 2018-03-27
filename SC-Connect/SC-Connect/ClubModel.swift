//
//  Club.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/4/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/// Model for holding data about a club.
struct Club {
  
  /// Stores the server's id for the club.
  var clubID: Int = -1
  
  /// Stores the name of the club.
  var clubName: String = ""
  
  /// Stores the name of the associated tag.
  var associatedTagName: String = ""
  
  /// Stores the names of the club's leaders.
  var clubLeaders = [String]()
  
  /// Stores the days of the week that the club meets.
  var meetingDays = [String]()
  
  /// Stores the time that the club meets (ex. lunch, after school, 1 pm, etc).
  var meetingTime: String = ""
  
  /// Stores the location where the club meets.
  var meetingLocation: String = ""
}
