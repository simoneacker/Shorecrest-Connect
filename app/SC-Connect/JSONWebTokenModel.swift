//
//  JSONWebToken.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 4/28/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/// Model for holding data about a JSON Web Token.
struct JSONWebToken {
  
  /// Stores the full JWT in the encoded form given by the server.
  var encodedString: String = ""
  
  /// Stores the parsed header information.
  var header = [String: Any]()
  
  /// Stores the parsed payload information
  var payload = [String: Any]()
  
  /// Stores the signature in its encoded and signed formed.
  var signature: String = ""
}
