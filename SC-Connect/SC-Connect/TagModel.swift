//
//  TagModel.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 2/8/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation

/**
    A label for one topic/group in the broader group-chat-like messaging system.
 
    - Note: Chose a struct instead of class because Tag model does not meet swift guidelines for using a class. (http://stackoverflow.com/questions/24232799/why-choose-struct-over-class/24232845)
 */
struct Tag {
  
  /// The server's identifier for the tag.
  var tagID: Int = -1
  
  /// The name of the tag.
  var tagName: String = ""
  
  /// The color for the tag (held as an integer index).
  var colorIndex: Int = -1
  
  /// The total number of messages posted to the tag.
  var messageCount: Int = -1
  
  /// The number of subscribers to the tag.
  var subscriberCount: Int = -1
  
}
