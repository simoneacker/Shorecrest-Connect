//
//  ScheduledGame.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/6/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/// Model for holding data about an upcoming sports game.
struct ScheduledSportsGame {
  
  /// Stores the name of the sport.
  var sportName: String = ""
  
  /// Stores the date of the scheduled game.
  var date: Date = Date()
  
  /// Stores the name of the opponent.
  var opponentName: String = ""
  
  /// Stores the location of the scheduled game.
  var locationName: String = ""
}
