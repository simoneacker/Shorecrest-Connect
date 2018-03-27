//
//  SocketIOManager.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 4/30/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import Foundation
import SocketIO

/// Manages connecting, emiting, listening, and disconnecting a socket with the server.
class SocketIOManager: NSObject {

  /// Singleton so every part of app stays in sync.
  public static let shared = SocketIOManager()
  
  /// The socket that is used to interact with the backend server.
  private var socket = SocketIOClient(socketURL: URL(string: NetworkConstants.socketURL)!, config: [.log(true)])
  
  // Used to listen for connect ack so this can send message to have the server put the user in the rooms for the tags that they are subscribed to.
  public func configure() {
    on(eventName: "connect") { (dataArray, socketAck) in
      SCConnectAPI.Socket.joinAllSubscribedRooms()
    }
  }
  
  /// Opens the socket connection.
  public func establishConnection() {
    socket.connect()
  }
  
  /// Closes the socket connection.
  public func closeConnection() {
    socket.disconnect()
  }
  
  /// Returns the socket's connection status.
  public func isConnected() -> Bool {
    if socket.status == .connected {
      return true
    }
    
    return false
  }
  
  /**
      Wrapper around the SocketIO send function that adds basic logging.
   
      - Note: Offers ack option in case server has a message.
   */
  public func emit(eventName: String, data: [String: Any], completion: (([Any]) -> ())?) {
    socket.emitWithAck(eventName, data).timingOut(after: 0) { [weak self] dataArray in
      self?.logEventWith(name: eventName, andData: dataArray)
      completion?(dataArray)
    }
  }
  
  /**
      Wrapper around the SocketIO listen function that adds basic logging.
   
      - Note: Offers ack option in case the client needs to acknowledge a message or send back some data.
   */
  public func on(eventName: String, completion: @escaping ([Any], SocketAckEmitter) -> ()) {
    socket.on(eventName) { [weak self] (dataArray, socketAck) in
      self?.logEventWith(name: eventName, andData: dataArray)
      completion(dataArray, socketAck)
    }
  }
  
  /**
      Takes the event name/data sent by the server and logs key information.
   
      - Parameters:
          - eventName: The name of the event.
          - dataArray: The data sent by the server.
   */
  private func logEventWith(name eventName: String, andData dataArray: [Any]) {
    if dataArray.count >= 1, let serverMessage = dataArray[0] as? String {
      Log("Response Message to Socket Event (\(eventName)): \(serverMessage)")
    } else {
      Log("Response to Socket Event (\(eventName)) did not contain a message.")
    }
  }
}
