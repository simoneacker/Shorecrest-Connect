//
//  LogManager.swift
//  Testbed for Messages Type Interface
//
//  Created by Simon Acker on 1/30/17.
//  Copyright © 2017 Shorecrest Computer Science. All rights reserved.
//

import Foundation

/**
    Prints the given log message to the console with extra function information if the debug flag is enabled.
 
    - Note: This function should be used to print extra information needed for debugging but not for a live build.
 
    - Parameters:
        - message: The log message to be printed.
        - function: The function information passed in by default to provide detail to the log print.
 */
func DebugLog(_ message: String, function: String = #function) {
  #if DEBUG
  print("\(function): \(message)")
  #endif
}

/**
    Prints the given log message to the console with extra function information.
 
    - Parameters:
        - message: The log message to be printed.
        - function: The function information passed in by default to provide detail to the log print.
 */
func Log(_ message: String, function: String = #function) {
  print("\(function): \(message)")
}
