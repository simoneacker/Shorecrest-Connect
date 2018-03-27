//
//  CreateTagViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/12/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import Eureka

class CreateTagViewController: FormViewController {
  
  let tagNameRow = TextRow("Tag Name (max: 8 characters)").cellSetup { cell, row in
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.add(rule: RuleMaxLength(maxLength: 8))
    row.validationOptions = .validatesOnDemand
  }
  let colorIndexRow = IntRow("Color Index (0 to 14)").cellSetup { cell, row in
    cell.textField.placeholder = row.tag
    row.add(rule: RuleRequired())
    row.add(rule: RuleGreaterOrEqualThan(min: 0))
    row.add(rule: RuleSmallerOrEqualThan(max: 14))
    row.validationOptions = .validatesOnDemand
  }
  
  /// Used to create the form.
  override func viewDidLoad() {
    super.viewDidLoad()
    
    let infoSection = Section()
    infoSection.append(tagNameRow)
    infoSection.append(colorIndexRow)
    
    form.append(infoSection)
  }
  
  /// Called when the create button is tapped.
  @IBAction func didTapCreate(_ sender: UIBarButtonItem) {
    let validationErrors = form.validate()
    if validationErrors.count == 0 {
      let tagName = tagNameRow.value!.lowercased()
      let colorIndex = colorIndexRow.value!
      
      SCConnectAPI.REST.Tags.createTagWith(name: tagName, colorIndex: colorIndex, completion: { [weak self] (tag) in
        if tag != nil {
          let alertController = UIAlertController(title: "Success", message: "Tag was created.", preferredStyle: .alert)
          let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
          alertController.addAction(okAction)
          DispatchQueue.main.async { [weak self] in
            self?.present(alertController, animated: true, completion: nil)
            self?.clearAllFields()
          }
        } else {
          let alertController = UIAlertController(title: "Error", message: "Tag could not be created. Please try again later.", preferredStyle: .alert)
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
      self?.tagNameRow.value = nil
      self?.tagNameRow.updateCell()
      self?.colorIndexRow.value = nil
      self?.colorIndexRow.updateCell()
    }
  }
}
