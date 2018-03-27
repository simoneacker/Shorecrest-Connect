//
//  EventInfoViewController.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 3/29/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import MapKit // For user location handling
import GoogleAPIClientForREST // For adding events to google calendar

class EventInfoViewController: UITableViewController {
  
  @IBOutlet weak var checkInButtonTableViewCell: CheckInButtonTableViewCell!
  @IBOutlet weak var eventInfoTableViewCell: EventInfoTableViewCell!
  @IBOutlet weak var mapTableViewCell: MapTableViewCell!
  var locationManager = CLLocationManager() //used to get user location updates
  var lastUserLocation = CLLocation()
  var refreshCheckInAvailabilityTimer: Timer?
  var passedInEvent = Event()
  
  /// Used to request location services permission, start listening for location updates, and fill in the table view cells with the data from the passed in event.
  override func viewDidLoad() {
    super.viewDidLoad()
    locationManager.requestWhenInUseAuthorization()
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyBest
      locationManager.startUpdatingLocation()
    }
    checkInButtonTableViewCell.delegate = self
    updateCheckInAvailability()
    eventInfoTableViewCell.event = passedInEvent
    mapTableViewCell.delegate = self
    mapTableViewCell.displayLocation(address: passedInEvent.locationAddress)
    mapTableViewCell.displayLocation(latitude: passedInEvent.locationLatitude, longitude: passedInEvent.locationLongitude)
  }
  
  /// Used to start the timer that checks if check in has become available.
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    refreshCheckInAvailabilityTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(updateCheckInAvailability), userInfo: nil, repeats: true)
  }
  
  /// Used to stop the timer that checks if check in has become available.
  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    refreshCheckInAvailabilityTimer?.invalidate()
  }
  
  // MARK: - Navigation
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) { //sender is a tag name string
    if segue.identifier == "eventInfoToCheckInList" {
      if let checkedInListVC = segue.destination as? CheckedInListViewController {
        checkedInListVC.passedInEvent = passedInEvent
      }
    }
  }
  
  
  /// Called when the user taps the add to calendar button.
  @IBAction func didTapAddToCalendar() {
    if UserManager.shared.userSignedIn() {
      UserManager.shared.createCalendarEvent(startDate: passedInEvent.startDate, endDate: passedInEvent.endDate, eventTitle: passedInEvent.eventName, eventDescription: "Location: \(passedInEvent.locationAddress)") { [weak self] (success) in
        let statusAlertController = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        statusAlertController.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        if success {
          statusAlertController.title = "Success"
          statusAlertController.message = "The event was added to your Google Calendar."
        } else {
          statusAlertController.title = "Error"
          statusAlertController.message = "The event could not be added to your Google Calendar. Try re-signing into your Google account if the problem persists."
        }
        self?.present(statusAlertController, animated: true, completion: nil)
      }
    } else {
      present(UserManager.shared.notSignedInAlertController(), animated: true, completion: nil)
    }
  }
  
  
  /// Used to evaluate and display if check in is available. If available, it gets the check in status of the current user and then updates the checkInButtonTableViewCell.
  func updateCheckInAvailability() {
    let currentDate = Date()
    if !UserManager.shared.userSignedIn() || currentDate < passedInEvent.startDate || currentDate > passedInEvent.endDate { // check in unavailable bc current date is not in start-end range
      checkInButtonTableViewCell.disableCheckIn()
    } else { // check in could be available
      if passedInEvent.userCheckedIn == nil { // if check in is generally available but user check in status not downloaded, download the status
        SCConnectAPI.REST.Events.checkInStatusToEventWith(id: passedInEvent.eventID, completion: { [weak self] (userCheckedIn) in
          DispatchQueue.main.async { [weak self] in
            self?.passedInEvent.userCheckedIn = userCheckedIn
            if userCheckedIn {
              self?.checkInButtonTableViewCell.markAsCheckedIn()
            } else {
              self?.checkInButtonTableViewCell.enableCheckIn()
            }
          }
        })
      } else if passedInEvent.userCheckedIn == true { // if user checked in
        checkInButtonTableViewCell.markAsCheckedIn()
      } else { // if user not checked in, they can now
        checkInButtonTableViewCell.enableCheckIn()
      }
    }
  }
}

extension EventInfoViewController: CheckInButtonTableViewCellDelegate {
  
  /// Used to check in the user to the event, but only if they are signed in and within the geolocation boundry.
  func didTapCheckIn() {
    let eventLocation = CLLocation(latitude: passedInEvent.locationLatitude, longitude: passedInEvent.locationLongitude)
    if UserManager.shared.userSignedIn() {
      if let selectedGraduationYear = UserManager.shared.getGraduationYear() {
        if lastUserLocation.distance(from: eventLocation) < 200 {
          SCConnectAPI.REST.Events.checkInToEventWith(id: passedInEvent.eventID, forGraduationYear: selectedGraduationYear, completion: { [weak self] (success) in
            if success {
              DispatchQueue.main.async { [weak self] in
                self?.passedInEvent.userCheckedIn = true
                self?.checkInButtonTableViewCell.markAsCheckedIn()
                if let event = self?.passedInEvent {
                  let alertController = UIAlertController(title: "Checked In", message: "Great work! You just earned \(event.leaderboardPoints) points by checking into this event.", preferredStyle: .alert)
                  alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
                  self?.present(alertController, animated: true, completion: nil)
                }
              }
            } // error
          })
        } else {
          let alertController = UIAlertController(title: "Too far away!", message: "You must be within 200 meters of the event and have location services enabled to check in.", preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
          present(alertController, animated: true, completion: nil)
        }
      } else {
        SCConnectAPI.REST.LeaderboardScores.getAvailableGraduationYears(completion: { [weak self] (graduationYears) in
          if graduationYears != nil {
            DispatchQueue.main.async { [weak self] in
              let alertController = UIAlertController(title: "Please select your graduation year", message: nil, preferredStyle: .alert)
              for graduationYear in graduationYears! {
                alertController.addAction(UIAlertAction(title: "\(graduationYear)", style: .default, handler: { [weak self, graduationYear] (action) in
                  UserManager.shared.setGraduation(year: graduationYear)
                  self?.didTapCheckIn() //try to check in again
                }))
              }
              alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
              self?.present(alertController, animated: true, completion: nil)
            }
          } else {
            DispatchQueue.main.async { [weak self] in
              let alertController = UIAlertController(title: "Error", message: "Something went wrong. Please try again later.", preferredStyle: .alert)
              alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
              self?.present(alertController, animated: true, completion: nil)
            }
          }
        })
      }
    } else {
      present(UserManager.shared.notSignedInAlertController(), animated: true, completion: nil)
    }
  }
}

extension EventInfoViewController: CLLocationManagerDelegate {
  
  /// Used to update variable with the user's last location.
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    if let lastLocation = locations.last {
      lastUserLocation = lastLocation
    }
  }
}

extension EventInfoViewController: MapTableViewCellDelegate {
  
  /// Used to open directions to the location in the maps app.
  func didTapGetDirections() {
    let location = CLLocation(latitude: passedInEvent.locationLatitude, longitude: passedInEvent.locationLongitude)
    let placemark = MKPlacemark(coordinate: location.coordinate)
    let mapItem = MKMapItem(placemark: placemark)
    mapItem.name = passedInEvent.locationName
    mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving])
  }
}
