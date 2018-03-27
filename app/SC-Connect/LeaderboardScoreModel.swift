//
//  LeaderboardScore.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/4/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/// Model for holding data about one user's leaderboard score.
struct LeaderboardScore {
  
  /// Stores the id of the score.
  var leaderboardScoreID: Int = -1
  
  /// Stores the name of the user to which the score belongs.
  var username: String = ""
  
  /// Stores the actual leaderboard points value.
  var score: Int = -1
  
}
