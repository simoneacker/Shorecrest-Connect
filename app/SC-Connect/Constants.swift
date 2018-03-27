//
//  Constants.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 3/9/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation
import AWSCore //for aws region
import UIKit //for color and device

// All constants and functions are static so call doesn't need to initialize an object of the struct type before using it.
/// Constants used for network requests to the server.
struct NetworkConstants {
  
  /// The foundation url of the server.
  private static let baseURL = "https://api.shorecrestconnect.com"
  
  /// The port for both sockets and REST.
  private static let port = 443
  
  /// The REST API url addition.
  private static let restURLAddition = "/scconnect/"
  
  /// The URL of the REST API.
  public static let restURL = NetworkConstants.baseURL + ":" + "\(NetworkConstants.port)" + NetworkConstants.restURLAddition
  
  /// The URL of the Socket API.
  public static let socketURL = NetworkConstants.baseURL + ":" + "\(NetworkConstants.port)"
}

/// Constants used to upload or download media content from AWS S3
struct AWSConstants {
  
  /// The region identifier for the bucket which stores the media.
  static let region = AWSRegionType.USWest2
  
  /// The AWS Cognito Pool Identifier for the bucket which stores the media.
  static let poolID = "us-west-2:e63203a1-e27a-4630-b3ee-55eb30ab0e32"
  
  /// The name of the bucket which stores all of the media content.
  static let bucketName = "scconnect-production"
}

/// Key constants for posting and observing NotificationCenter notifications. Used to decrease chance of mistyping and make changes easier.
struct NotificationCenterConstants {
  
  /// Called when a user has successfully signed into their google account.
  static let googleUserSignedInKey = "GoogleUserSignedIn"
  
  /// Called when a user has successfully signed out of their google account.
  static let googleUserSignedOutKey = "GoogleUserSignedOut"
  
  /// Called when the user changes their selected graduation year.
  static let graduationYearChangedKey = "GraduationYearChanged"
  
  /// Called when a tag's color is changed.
  static let tagColorChangedKey = "TagColorChanged"
  
  /// Called when a new message is posted by the user.
  static let newMessagePostedKey = "NewMessagePosted"
  
  /// Called when the user subscribes or unsubscribes from a tag.
  static let subscriptionsChangedKey = "SubscriptionsChanged"
  
  /// Called when the user reads at least one new message.
  static let lastReadMessagesChangedKey = "LastReadMessagesChanged"
  
  /// Called when the selected sport is changed.
  static let selectedSportChangedKey = "SelectedSportChanged"
  
  /// Called when the an image has been uploaded to fan cam.
  static let fanCamImageCreatedKey = "FanCamImageCreated"
  
  /// Called when the day of the week is changed on clubs page.
  static let clubsSelectedDayOfWeekChangedKey = "ClubsSelecgtedDayOfWeekChanged"
  
  /// Called when the selected graduation year is changed.
  static let selectedGraduationYearChangedKey = "SelectedGraduationYearChanged"
}

/// Key constants for saving and accessing information saved to UserDefaults. Used to decrease chance of mistyping and make changes easier.
struct UserDefaultsConstants {
  
  /// The key which references information about the signed in user, if there is one.
  static let googleUserInfoKey = "GoogleUserInfo"
  
  /// The key which references a dictionary that holds the identifier (value) of the last read message for each of the subscribed tags by name (key).
  static let lastReadMessageIdentifiersKey = "LastReadMessageIdentifiers"
  
  /// The key which references information about the current authentication session, if there is one.
  static let jwtKey = "JSONWebToken"
  
  /// The key which references information about the signed in user's selected graduation year. Empty if no Google Account signed in.
  static let graduationYearKey = "GraduationYear"
  
  /// The key which references a boolean about whether or not the user has completed the tutorial.
  static let tutorialCompletedKey = "TutorialCompleted"
  
  /// The key which references a boolean about whether or not the school property warning alert has been shown.
  static let schoolPropertyWarningShownKey = "SchoolPropertyWarningShown"
}

/// Constant names for all icon images called in code. Used to make changing an icon easier.
struct IconNameConstants {
  
  /// Used by the tag color picker to highlight which color is currently selected.
  static let checkmark = "color_picker_checkmark_icon_inverted"
}

/// All URLs used within the app.
struct URLConstants {
  
  /// The link of information about the app and components/media used in it.
  static let aboutURL = "http://www.shorecrestconnect.com/scconnect-about.html"
  
  /// The link of information about terms of use agreed upon by using the app.
  static let termsOfUseURL = "http://www.shorecrestconnect.com/terms_of_use.pdf"
  
  /// The link of information about the EULA agreed upon by using the app.
  static let endUserLiscenseAgreementURL = "http://www.shorecrestconnect.com/EULA.pdf"
  
  /// The link of information about the privacy policy agreed upon by using the app.
  static let privacyPolicyURL = "http://www.shorecrestconnect.com/Privacy%20Policy.pdf"
  
  /// The link of the daily bulletin.
  static let dailyBulletinURL = "http://www.shorelineschools.org/site/Default.aspx?PageType=3&DomainID=19&PageID=31&ViewID=ed695a1c-ef13-4546-b4eb-4fefcdd4f389&FlexDataID=4221"
  
  /// The link of the school calendar.
  static let schoolCalendarURL = "http://www.shorelineschools.org/site/Default.aspx?PageID=32"
  
  /// The link of the highlander home google calendar in agenda mode by default.
  static let hhScheduleURL = "https://calendar.google.com/calendar/embed?src=johanna.phillips@k12.shorelineschools.org&ctz=America/Los_Angeles&pli=1&mode=AGENDA"
  
  /// The link of Mr. Mitchell's video's page on YouTube.
  static let videosURL = "https://www.youtube.com/channel/UCJkBDvKzeAwYKFCkG5--9Qw/videos?sort=dd&view=0&shelf_id=0"
}

/// All constants used for storing, parsing or displaying tag information.
struct TagConstants {
  
  /**
      Gives the color information for one of the color indexes.
      
      - Note: Using a function because it is much simpler than having 15 named colors like colorOne, colorTwo, etc.
   
      - Parameters:
          - index: The integer index of the color (0-14).
   
      - Returns: UIColor with the RGB values for that specific color index.
   */
  static func colorFor(index: Int) -> UIColor {
    switch index { //using a switch for readability and easy defaulting
    case 0:
      return UIColor(red: 0.35, green: 0.18, blue: 0.55, alpha: 1.0)
    case 1:
      return UIColor(red: 0.71, green: 0.12, blue: 0.45, alpha: 1.0)
    case 2:
      return UIColor(red: 0.91, green: 0.12, blue: 0.15, alpha: 1.0)
    case 3:
      return UIColor(red: 0.90, green: 0.36, blue: 0.15, alpha: 1.0)
    case 4:
      return UIColor(red: 0.90, green: 0.51, blue: 0.15, alpha: 1.0)
    case 5:
      return UIColor(red: 0.89, green: 0.71, blue: 0.13, alpha: 1.0)
    case 6:
      return UIColor(red: 0.90, green: 0.90, blue: 0.09, alpha: 1.0)
    case 7:
      return UIColor(red: 0.49, green: 0.04, blue: 0.26, alpha: 1.0)
    case 8:
      return UIColor(red: 0.09, green: 0.62, blue: 0.29, alpha: 1.0)
    case 9:
      return UIColor(red: 0.09, green: 0.57, blue: 0.70, alpha: 1.0)
    case 10:
      return UIColor(red: 0.04, green: 0.34, blue: 0.64, alpha: 1.0)
    case 11:
      return UIColor(red: 0.16, green: 0.20, blue: 0.54, alpha: 1.0)
    case 12:
      return UIColor(red: 0.37, green: 0.37, blue: 0.37, alpha: 1.0)
    case 13:
      return UIColor(red: 0.61, green: 0.61, blue: 0.61, alpha: 1.0)
    case 14:
      return UIColor(red: 0.77, green: 0.77, blue: 0.77, alpha: 1.0)
    default:
      return UIColor.clear
    }
  }
}
