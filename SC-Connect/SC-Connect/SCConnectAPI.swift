//
//  SCConnectRESTAPI.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/2/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/**
    The overarching struct that contains the REST and Socket APIs to make the calls to them more readable.
 
    - Note: Uses REST API to download existing messages and Socket.io to create messages and get ones created while the app is open.
 */
struct SCConnectAPI {
  
  static let Socket = SCConnectSocketAPI.self
  
  static let REST = SCConnectRESTAPI.self
  
}
