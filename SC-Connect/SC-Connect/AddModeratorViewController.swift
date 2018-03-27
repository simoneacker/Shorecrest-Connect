//
//  AddModeratorViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/13/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import Eureka

class AddModeratorViewController: FormViewController {
  
  let emailRow = TextRow("@k12.shorelineschools.org Email").cellSetup { cell, row in
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.add(rule: RuleEmail())
    row.validationOptions = .validatesOnDemand
  }
  
  /// Used to create the form.
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let infoSection = Section()
    infoSection.append(emailRow)
    
    form.append(infoSection)
  }
  
  /// Called when the create button is tapped.
  @IBAction func didTapCreate(_ sender: UIBarButtonItem) {
    let validationErrors = form.validate()
    if validationErrors.count == 0 {
      let emailAddress = emailRow.value!
      
      SCConnectAPI.REST.Admins.promoteUserBy(email: emailAddress, completion: { (success) in
        if success {
          let alertController = UIAlertController(title: "Success", message: "User is now a moderator", preferredStyle: .alert)
          let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
          alertController.addAction(okAction)
          DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true, completion: nil)
            self?.clearAllFields()
          }
        } else {
          let alertController = UIAlertController(title: "Error", message: "User could not be promoted to moderator status. Please ensure they have signed into the app at least once and try again later.", preferredStyle: .alert)
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
      self?.emailRow.value = nil
      self?.emailRow.updateCell()
    }
  }
}
