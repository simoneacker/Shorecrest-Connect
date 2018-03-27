//
//  CreateClubViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/4/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import Eureka

class CreateClubViewController: FormViewController {
  
  let clubNameRow = TextRow("Club Name (max: 64 characters)").cellSetup { cell, row in // Club info section
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.add(rule: RuleMaxLength(maxLength: 64))
    row.validationOptions = .validatesOnDemand
  }
  let associatedTagNameRow = TextRow("Associated Tag Name (max: 8 characters)").cellSetup { cell, row in
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.add(rule: RuleMaxLength(maxLength: 8))
    row.validationOptions = .validatesOnDemand
  }
  
  let meetingTimeRow = TextRow("Meeting Time (ex: Lunch. max: 64 characters)").cellSetup { cell, row in // Meeting info section
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.add(rule: RuleMaxLength(maxLength: 64))
    row.validationOptions = .validatesOnDemand
  }
  let meetingLocationRow = TextRow("Meeting Location (max: 64 characters)").cellSetup { cell, row in
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.add(rule: RuleMaxLength(maxLength: 64))
    row.validationOptions = .validatesOnDemand
  }
  
  /// Used to create a new multivalued section for the club leader names.
  func clubLeaderNamesSection() -> MultivaluedSection {
    return MultivaluedSection(multivaluedOptions: [.Insert, .Delete], header: "", footer: "") { (section) in
      section.addButtonProvider = { section in // Add row button row
        return ButtonRow().cellSetup { cell, row in
          row.title = "Add New Leader Name"
        }
      }
      section.multivaluedRowToInsertAt = { index in // Row to insert when requested
        return TextRow().cellSetup { cell, row in
          cell.textField.placeholder = "Leader Name (max: 32 characters)"
          row.add(rule: RuleRequired())
          row.add(rule: RuleMaxLength(maxLength: 32))
          row.validationOptions = .validatesOnDemand
        }
      }
      section.append(TextRow().cellSetup { cell, row in // Initial row
        cell.textField.placeholder = "Leader Name (max: 32 characters)"
        row.add(rule: RuleRequired())
        row.add(rule: RuleMaxLength(maxLength: 32))
        row.validationOptions = .validatesOnDemand
      })
    }
  }
  
  /// Used to create a new multivalued section for the meeting days.
  func meetingDaysSection() -> MultivaluedSection {
    return MultivaluedSection(multivaluedOptions: [.Insert, .Delete], header: "", footer: "") { (section) in
      section.addButtonProvider = { section in // Add row button row
        return ButtonRow().cellSetup { cell, row in
          row.title = "Add New Meeting Day"
        }
      }
      section.multivaluedRowToInsertAt = { index in // Row to insert when requested
        return ActionSheetRow<String>().cellSetup { cell, row in
          row.title = "Meeting Day"
          row.options = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
          row.value = "Tuesday" // Initial value
          row.add(rule: RuleRequired())
          row.validationOptions = .validatesOnDemand
        }
      }
      section.append(ActionSheetRow<String>().cellSetup { cell, row in // Initial row
        row.title = "Meeting Day"
        row.options = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]
        row.value = "Monday" // Initial value
        row.add(rule: RuleRequired())
        row.validationOptions = .validatesOnDemand
      })
    }
  }
  
  /// Used to create the form.
  override func viewDidLoad() {
    super.viewDidLoad()
    
    refreshForm()
  }
  
  /// Used to create/re-create the form.
  func refreshForm() {
    form.removeAll()
    
    let clubInfoSection = Section()
    clubInfoSection.append(clubNameRow)
    clubInfoSection.append(associatedTagNameRow)
    
    let meetingInfoSection = Section()
    meetingInfoSection.append(meetingTimeRow)
    meetingInfoSection.append(meetingLocationRow)
    
    form.append(clubInfoSection)
    form.append(clubLeaderNamesSection())
    form.append(meetingDaysSection())
    form.append(meetingInfoSection)
  }
  
  /// Called when the create button is tapped.
  @IBAction func didTapCreate(_ sender: UIBarButtonItem) {
    let validationErrors = form.validate()
    let clubLeaderNamesSection = form[1]
    let meetingDaysSection = form[2]
    if validationErrors.count == 0 && clubLeaderNamesSection.count >= 2 && meetingDaysSection.count >= 2 { // Multivalued sections need two rows bc one data and an "add more" row
      let clubName = clubNameRow.value!
      let associatedTagName = associatedTagNameRow.value!.lowercased()
      var clubLeaders = [String]()
      for i in 0..<clubLeaderNamesSection.count {
        if let leaderNameRow = clubLeaderNamesSection[i] as? TextRow {
          clubLeaders.append(leaderNameRow.value!)
        }
      }
      var meetingDays = [String]()
      for i in 0..<meetingDaysSection.count {
        if let meetingDayRow = meetingDaysSection[i] as? ActionSheetRow<String> {
          meetingDays.append(meetingDayRow.value!)
        }
      }
      let meetingTime = meetingTimeRow.value!
      let meetingLocation = meetingLocationRow.value!
      
      SCConnectAPI.REST.Clubs.createClubWith(name: clubName, associatedTagName: associatedTagName, clubLeaders: clubLeaders, meetingDays: meetingDays, meetingTime: meetingTime, meetingLocation: meetingLocation, completion: { (club) in
        if club != nil {
          let alertController = UIAlertController(title: "Success", message: "Club was created.", preferredStyle: .alert)
          let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
          alertController.addAction(okAction)
          DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true, completion: nil)
            self?.refreshForm()
          }
        } else {
          let alertController = UIAlertController(title: "Error", message: "Club could not be created. Please try again later.", preferredStyle: .alert)
          let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
          alertController.addAction(okAction)
          DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true, completion: nil)
            self?.refreshForm()
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
}
