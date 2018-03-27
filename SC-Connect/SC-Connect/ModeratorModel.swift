//
//  Moderator.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/13/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/// Model for holding data about a user that is marked as a moderator.
struct Moderator {
  
  /// Stores the server's identifier for the moderator.
  var moderatorID: Int = -1
  
  /// Stores the name of the moderator.
  var name: String = ""
  
  /// Stores the email address of the moderator.
  var email: String = ""
}
