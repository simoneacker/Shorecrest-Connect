//
//  GoogleUserModel.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 3/9/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation

/// Model for holding data about the google user that is signed in. No initializers because a struct automatically has one ititializer to fill in all properties.
struct GoogleUser {
  
  /// The identifier for the user given by google.
  var googleID: String = ""
  
  /// The email address used to login. It must be an @k12.shorelineschools.org account in order to prevent non Shoreline School District users from logging in and posting content.
  var email: String = ""
  
  /// The first name of the user.
  var firstName: String = ""
  
  /// The last name of the user.
  var lastName: String = ""
  
  /// Stores whether or not the user is a moderator once it is downloaded.
  var isModerator: Bool = false
  
  /// Stores whether or not the user is an admin once it is downloaded.
  var isAdmin: Bool = false
}
