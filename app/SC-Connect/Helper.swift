//
//  Helper.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/2/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation

/// Unchanging functions used throughout the project.
struct Helper {
  
  /**
      Takes a JSON string and attempts to decode it into a dictionary.
   
      - Parameters:
          - jsonString: A JSON string that should contain a dictionary.
   
      - Returns: An optional dictionary because decode could fail.
   */
  public static func decodeJSONStringIntoDictionary(jsonString: String) -> NSDictionary? {
    if let jsonData = jsonString.data(using: String.Encoding.utf8) {
      do {
        let jsonDictionary = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments) as! NSDictionary
        return jsonDictionary
      } catch let error {
        Log("Error decoding JSON String into Dictionary: \(error)")
      }
    }
    
    return nil
  }
  
  /**
      Takes a dictionary and attempts to encode it into a JSON string.
   
      - Parameters:
          - dictionary: A dictionary object.
   
      - Returns: An optional JSON string because the encode could fail.
   */
  public static func encodeDictionaryIntoJSONString(dictionary: [String: Any]) -> String? {
    do {
      let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: JSONSerialization.WritingOptions(rawValue: 0)) //not pretty printed to save space
      if let jsonString = NSString(data: jsonData, encoding: String.Encoding.utf8.rawValue) as String? {
        return jsonString
      }
    } catch {
      Log("Error encoding Dictionary into JSON String: \(error)")
    }
    
    return nil
  }
  
  /**
      Generates a random alphanumeric (lowercase, uppercase, 0-9) string of the given length.
   
      - Note: This method is similar to Dschee's answer on stack overflow (http://stackoverflow.com/questions/26845307/generate-random-alphanumeric-string-in-swift).
   
      - Parameters:
          - length: The requested number of characters for the generated string.
   */
  public static func randomAlphaNumericString(length: Int) -> String {
    var generatedString = ""
    let possibleCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    let possibleCharactersCount = UInt32(possibleCharacters.characters.count)
    for _ in 0..<length {
      let randomNumber = Int(arc4random_uniform(possibleCharactersCount))
      let indexOfRandomCharacter = possibleCharacters.index(possibleCharacters.startIndex, offsetBy: randomNumber)
      let randomCharacter = possibleCharacters[indexOfRandomCharacter]
      generatedString += String(randomCharacter)
    }
    
    return generatedString
  }
  
  /**
      Creates a MySQL Timestamp formatted string from a Date object.
   
      - Parameters:
          - date: A Date object that will be used to create the formatted string.
   
      - Returns: Formatted string.
   */
  public static func MySQLTimestampFormattedStringFrom(date: Date) -> String {
    
    return stringFrom(date: date, withFormat: "yyyy.MM.dd HH:mm:ss")
  }
  
  /**
      Parses a string in the MySQL Timestamp date format into a Date object. 
   
      - Note: Removes the timezone, so date is what it is in the current timezone.
   
      - Parameters:
          - formattedString: A string in the MySQL Timestamp date format (https://dev.mysql.com/doc/refman/5.7/en/datetime.html).
   
      - Returns: Optional Date object.
   */
  public static func dateFromMySQLTimestamp(formattedString: String) -> Date? {
    let indexOfTimezone = formattedString.index(formattedString.startIndex, offsetBy: 19)
    return dateFrom(string: formattedString.substring(to: indexOfTimezone), withFormat: "yyyy.MM.dd'T'HH:mm:ss")
  }
  
  /**
      Creates a iso8601 formatted string from a Date object.
   
      - Parameters:
          - date: A Date object that will be used to create the formatted string.
   
      - Returns: Formatted string.
   */
  public static func iso8601FormattedStringFrom(date: Date) -> String {
    
    return stringFrom(date: date, withFormat: "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX")
  }
  
  /**
      Creates a string to represent the day of the date. Ex. Today or Yesterday or Sun, May 7.
   
      - Paramters:
          - date: The date used to create the string.
   
      - Returns: String representation for the day of the date.
   */
  public static func dayStringFrom(date: Date) -> String {
    var dayString = ""
    if Calendar.current.isDateInToday(date) {
      dayString = "Today"
    } else if Calendar.current.isDateInYesterday(date) {
      dayString = "Yesterday"
    } else if Calendar.current.isDateInTomorrow(date) {
      dayString = "Tomorrow"
    } else {
      dayString = stringFrom(date: date, withFormat: "EEE, MMM d")
    }
    
    return dayString
  }
  
  /**
      Creates a string to represent the time of the date. Ex. 11:59 AM or 12:00 PM.
   
      - Paramters:
          - date: The date used to create the string.
   
      - Returns: String representation for the time of the date.
   */
  public static func timeStringFrom(date: Date) -> String {
    
    return stringFrom(date: date, withFormat: "h:mm a")
  }
  
  /**
      Creates a string from the date with whatever format is given.
   
      - Paramters:
          - date: The date used to create the string.
          - format: The format of the string that will be created. This must be a valid format string as set by DateFormatter.
   
      - Returns: String representation of the date in the given format.
   */
  public static func stringFrom(date: Date, withFormat format: String) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    
    return dateFormatter.string(from: date)
  }
  
  /**
      Creates a date from the string in the given format.
   
      - Paramters:
          - string: The string used to create the date that should match the given format.
          - format: The format of the given string. This must be a valid format string as set by DateFormatter.
   
      - Returns: Optional Date object.
   */
  public static func dateFrom(string: String, withFormat format: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = format
    
    return dateFormatter.date(from: string)
  }
}
