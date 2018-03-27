//
//  SportsGameResult.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/6/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/// Model for holding data about the result of a sports game.
struct SportsGameResult {
  
  /// Stores the name of the sport.
  var sportName: String = ""
  
  /// Stores the date of the game.
  var date: Date = Date()
  
  /// Stores the name of the opponent.
  var opponentName: String = ""
  
  /// Stores the score of the opposing team.
  var opponentScore: Int = -1
  
  /// Stores the score of the home team.
  var homeScore: Int = -1
}
