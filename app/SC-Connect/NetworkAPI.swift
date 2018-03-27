//
//  NetworkManager.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 1/29/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation

/**
    The level of abstraction below the SC-Connect APIs and session information that handles the actual web requests.
 
    - Note: All functions are static so they can be called without initializing a `NetworkAPI` object.
 */
struct NetworkAPI {
  
  /**
      Creates a GET query URL from the `NetworkConstants.baseURL`, a string addition, and a dictionary of string parameters.
   
      - Parameters: 
          - urlPathAddition: A string addition to the URL path.
          - parameters: An optional string dictionary that will be formatted to form the end of the query URL. Dictionary keys should used camelCase.
      - Returns: A URL object if the data was valid or nil if not.
   */
  public static func makeGETQueryURLToBasePathWith(pathAddition: String, parameters: [String: String]?) -> URL? {
    
    // Build the formatted parameters part of the query
    var formattedParameterString = "?"
    if parameters != nil {
      
      // Format and add each parameter to the string
      var counter = 0
      for (key, value) in parameters! {
        formattedParameterString += "\(key)=\(value)"
        if counter < parameters!.count - 1 {
          formattedParameterString += "&" // The & symbol references that there will be another parameter
        }
        counter += 1
      }
    }
    
    // Attempt to combine the path and parameters to complete the query URL
    return URL(string: NetworkConstants.restURL + pathAddition + formattedParameterString)
  }
  
  /**
      Creates, sends, handles, and parses a GET request to the given query URL.
   
      - Note: The response data from the request is expected to be in JSON format. This method parse the json into a dictionary for easier use.
      - Parameters:
          - url: The query url that information is requested from.
          - completion: The handler called when the web request is completed. Needs to accept a dictionary of the parsed response data.
   */
  public static func GETRequestTo(url: URL, completion: @escaping ([String: Any]?) -> ()) {
    
    // Create the GET request
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "GET"
    let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
      
      // Handle the response
      if error == nil, let responseData = data {
        
        // Parse the response data
        do {
          let parsedResponseData = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as! [String: Any] // Forced cast will also be caught if it fails
          DebugLog("GET Request to url (\(url)) succeeded.") // Parsed JSON is: \(parsedResponseData)
          completion(parsedResponseData)
        } catch {
          DebugLog("GET Request to url (\(url)) failed. Error parsing JSON response data.")
          completion(nil)
        }
        
      } else {
        DebugLog("GET Request to url (\(url)) failed. Error: \(error.debugDescription).")
        completion(nil)
      }
    }
    
    // Send the request off
    dataTask.resume()
  }
  
  /**
      Creates a POST URL from the `NetworkConstants.baseURL` and a string addition.
   
      - Parameters:
          - urlPathAddition: A string addition to the URL path.
      - Returns: A URL object if the data was valid or nil if not.
   */
  public static func makePOSTURLToBasePathWith(pathAddition: String) -> URL? {
    
    // Attempt to combine the base path and addition to complete the URL
    return URL(string: NetworkConstants.restURL + pathAddition)
  }
  
  /**
      Creates, sends, and handles a POST request to the given URL.
   
      - Note: The body of the POST request is converted to and sent as JSON.
      - Parameters:
          - url: The query url that information is requested from.
          - body: A dictionary of info that will be JSON encoded and passed as the body of the POST request. All keys should be lowercase and each word should be separated by an underscore.
          - completion: The handler called when the web request is completed. Needs to accept an http status code from the response.
   */
  public static func POSTRequestTo(url: URL, with body: [String: Any]?, completion: @escaping (Int) -> ()) {
    
    // Convert the body, if exists, to json
    var jsonBody = Data()
    if body != nil {
      if let jsonData = jsonify(object: body!) {
        jsonBody = jsonData
      } else {
        DebugLog("Invalid URL or parameters at POST Request")
        completion(-1)
        return // Exit the function
      }
    }
    
    // Create the POST request
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type") //needed or server won't parse the data
    urlRequest.httpBody = jsonBody
    let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
      
      // Handle the response
      if error == nil, response != nil, let httpResponse = response! as? HTTPURLResponse {
        DebugLog("POST Request to url (\(url)) completed. Returned status code: \(httpResponse.statusCode).")
        completion(httpResponse.statusCode)
      } else {
        DebugLog("POST Request to url (\(url)) failed.  Error: \(error.debugDescription).")
        completion(-1)
      }
    }
    
    // Send the request off
    dataTask.resume()
  }
  
  /**
      Creates, sends, handles, and parses a POST request to the given URL.
   
      - Note: The body of the POST request is converted to and sent as JSON.
      - Note: The response data from the request is expected to be in JSON format. This method parses the json into a dictionary for easier use.
      - Parameters:
          - url: The query url that information is requested from.
          - body: A dictionary of info that will be JSON encoded and passed as the body of the POST request. All keys should be lowercase and each word should be separated by an underscore.
          - completion: The handler called when the web request is completed. Needs to accept an http status code from the response and a dictionary of the parsed response data.
   */
  public static func POSTRequestWithDataResponseTo(url: URL, with body: [String: Any]?, completion: @escaping (Int, [String: Any]?) -> ()) {
    
    // Convert the body, if exists, to json
    var jsonBody = Data()
    if body != nil {
      if let jsonData = jsonify(object: body!) {
        jsonBody = jsonData
      } else {
        DebugLog("Invalid URL or parameters at POST Request")
        completion(-1, nil)
        return // Exit the function
      }
    }
    
    // Create the POST request
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type") //needed or server won't parse the data
    urlRequest.httpBody = jsonBody
    let dataTask = URLSession.shared.dataTask(with: urlRequest) { (data, response, error) in
      
      // Handle the response
      if error == nil, response != nil, let httpResponse = response! as? HTTPURLResponse, let responseData = data { // Longer if bc needs both response info and data
        
        // Parse the response data
        do {
          let parsedResponseData = try JSONSerialization.jsonObject(with: responseData, options: .allowFragments) as! [String: Any] // Forced cast will also be caught if it fails
          DebugLog("POST Request With Data Response to url (\(url)) succeeded.") // Returned status code: \(httpResponse.statusCode) and JSON data: \(parsedResponseData).
          completion(httpResponse.statusCode, parsedResponseData)
        } catch {
          DebugLog("POST Request With Data Response to url (\(url)) failed. JSON response parse failed.")
          completion(-1, nil)
        }
        
      } else {
        DebugLog("POST Request With Data Response to url (\(url)) failed. Error: \(error.debugDescription).")
        completion(-1, nil)
      }
    }
    
    // Send the request off
    dataTask.resume()
  }
  
  /**
      Attempts to convert the given object into JSON data.
   
      - Parameters:
          - object: The optional object that will be converted into json.
      - Returns: If successful, it returns JSON Data. Otherwise it returns nil.
   */
  private static func jsonify(object: Any) -> Data? {
    do {
      return try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
    } catch {
      return nil
    }
  }
}
