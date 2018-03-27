//
//  GraduationYearManager.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/13/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/**
    Manages storing and retrieving the signed in user's selected graduation year.
 
    - Note: The shared info should always be in sync with the `GoogleManager` shared instance. If a user is signed in, there should be a selected graduation year and vice versa.
 */
class GraduationYearManager: NSObject {
  
  /// Stores the currently selected graduation year for the signed in user.
  private var graduationYear: Int?
  
  /// Used to load the currently selected graduation year from file.
  public func configure() {
    if let selectedGraduationYearFromDefaults = UserDefaults.standard.object(forKey: UserDefaultsConstants.graduationYearKey) as? Int {
      graduationYear = selectedGraduationYearFromDefaults
    }
  }
  
  /// Returns the currently selected graduation year if there is one.
  public func getGraduationYear() -> Int? {
    return graduationYear
  }
  
  /**
      Sets the current graduation year.
   
      - Parameters:
          - year: The selected graduation year that will be stored.
   */
  public func setGraduation(year: Int) {
    graduationYear = year
    UserDefaults.standard.set(year, forKey: UserDefaultsConstants.graduationYearKey)
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.selectedGraduationYearChangedKey), object: nil)
  }
  
  /// Clears the graduation year store.
  public func removeGraduationYear() {
    graduationYear = nil
    UserDefaults.standard.removeObject(forKey: UserDefaultsConstants.graduationYearKey)
    NotificationCenter.default.post(name: NSNotification.Name(rawValue: NotificationCenterConstants.selectedGraduationYearChangedKey), object: nil)
  }
}
