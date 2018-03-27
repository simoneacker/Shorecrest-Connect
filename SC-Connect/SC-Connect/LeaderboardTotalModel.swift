//
//  LeaderboardTotalModel.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/13/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/// Model for holding data about the totals points a graduating class has.
struct LeaderboardTotal {
  
  /// Stores the year the class graduates
  var graduationYear: Int = -1
  
  /// Stores the total number of points the graduating class has accumulated.
  var totalPoints: Int = -1
}
