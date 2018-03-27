//
//  ModeratorViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/11/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import Eureka
import MapKit

class CreateEventViewController: FormViewController {
  
  let eventNameRow = TextRow("Event Name").cellSetup { cell, row in
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.validationOptions = .validatesOnDemand
  }
  let checkInPointsRow = IntRow("Check-In Points (1 to 100)").cellSetup { cell, row in
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.add(rule: RuleGreaterOrEqualThan(min: 1))
    row.add(rule: RuleSmallerOrEqualThan(max: 100))
    row.validationOptions = .validatesOnDemand
  }
  
  let startDateTimeRow = DateTimeInlineRow("Check-In Starts") {
    $0.title = $0.tag
    $0.value = Date().addingTimeInterval(60 * 60 * 24) // Adds a day to current date
  }
  let endDateTimeRow = DateTimeInlineRow("Check-In Ends"){
    $0.title = $0.tag
    $0.value = Date().addingTimeInterval(60 * 60 * 25) // Adds day and one hour to current date
  }
  
  let locationNameRow = TextRow("Location Name").cellSetup { cell, row in
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.validationOptions = .validatesOnDemand
  }
  let locationAddressRow = TextRow("Location Address").cellSetup { cell, row in
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.validationOptions = .validatesOnDemand
  }
  let locationMapRow = LocationRow(){
    $0.title = "Check-In Lat/Long"
    $0.value = CLLocation(latitude: 47.741672, longitude: -122.305791)
  }
  
  /// Used to create the form.
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let infoSection = Section()
    infoSection.append(eventNameRow)
    infoSection.append(checkInPointsRow)
    
    let dateSection = Section()
    dateSection.append(startDateTimeRow)
    dateSection.append(endDateTimeRow)
    
    let locationSection = Section()
    locationSection.append(locationNameRow)
    locationSection.append(locationAddressRow)
    locationSection.append(locationMapRow)
    
    form.append(infoSection)
    form.append(dateSection)
    form.append(locationSection)
  }
  
  /// Called when the create button is tapped.
  @IBAction func didTapCreate(_ sender: UIBarButtonItem) {
    let validationErrors = form.validate()
    if validationErrors.count == 0 && endDateTimeRow.value! > startDateTimeRow.value! { //end date must be after start date
      let eventName = eventNameRow.value!
      let checkInPoints = checkInPointsRow.value!
      let startDate = startDateTimeRow.value!
      let endDate = endDateTimeRow.value!
      let locationName = locationNameRow.value!
      let locationAddress = locationAddressRow.value!
      let locationCoordinate = locationMapRow.value!
      
      SCConnectAPI.REST.Events.createEventWith(name: eventName, checkInPoints: checkInPoints, startDate: startDate, endDate: endDate, locationName: locationName, locationAddress: locationAddress, locationLatitude: locationCoordinate.coordinate.latitude, locationLongitude: locationCoordinate.coordinate.longitude, completion: { [weak self] (event) in
        if event != nil {
          let alertController = UIAlertController(title: "Success", message: "Event was created.", preferredStyle: .alert)
          let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
          alertController.addAction(okAction)
          DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true, completion: nil)
            self?.clearAllFields()
          }
        } else {
          let alertController = UIAlertController(title: "Error", message: "Event could not be created. Please try again later.", preferredStyle: .alert)
          let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
          alertController.addAction(okAction)
          DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true, completion: nil)
            self?.clearAllFields()
          }
        }
      })
    } else {
      let alertController = UIAlertController(title: "Validation Error", message: "Please ensure all fields are completed and within the written bounds.", preferredStyle: .alert)
      let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
      alertController.addAction(okAction)
      present(alertController, animated: true, completion: nil)
    }
  }
  
  /// Resets all fields to their default values.
  func clearAllFields() {
    DispatchQueue.main.async { [weak self] in
      self?.eventNameRow.value = nil
      self?.eventNameRow.updateCell()
      self?.checkInPointsRow.value = nil
      self?.checkInPointsRow.updateCell()
      self?.startDateTimeRow.value = Date().addingTimeInterval(60 * 60 * 24) // Adds a day to current date
      self?.startDateTimeRow.updateCell()
      self?.endDateTimeRow.value = Date().addingTimeInterval(60 * 60 * 25) // Adds day and one hour to current date
      self?.endDateTimeRow.updateCell()
      self?.locationNameRow.value = nil
      self?.locationNameRow.updateCell()
      self?.locationAddressRow.value = nil
      self?.locationAddressRow.updateCell()
      self?.locationMapRow.value = CLLocation(latitude: 47.741672, longitude: -122.305791)
      self?.locationMapRow.updateCell()
    }
  }
}
