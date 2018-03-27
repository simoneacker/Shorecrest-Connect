//
//  ManageClubsTableViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/4/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class ManageClubsTableViewController: UITableViewController {
  
  /// Holds the clubs once they are downloaded.
  var clubs = [Club]()
  
  /// Used to setup table view and download all of the clubs.
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = 250 //overestimate
    tableView.rowHeight = UITableViewAutomaticDimension
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshClubs), for: .valueChanged)
    refreshClubs()
  }
  
  /// Used to pass the selected club info to the edit view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "manageClubsToEditClub"{
      if let cell = sender as? ClubInfoTableViewCell {
        if let destinationVC = segue.destination as? EditClubViewController {
          destinationVC.passedInClub = cell.club ?? Club()
        }
      }
    }
  }
  
  /// Called when the user toggles editing mode.
  @IBAction func didToggleEditingMode(_ sender: UIBarButtonItem) {
    if tableView.isEditing {
      tableView.setEditing(false, animated: true)
      sender.title = "Edit"
    } else {
      tableView.setEditing(true, animated: true)
      sender.title = "Done"
    }
  }
  
  /// Used to download and store all clubs.
  func refreshClubs() {
    SCConnectAPI.REST.Clubs.getAllClubs { [weak self] (clubs) in
      if clubs != nil {
        self?.clubs = clubs!
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
      }
    }
  }
  
  // MARK: - UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return clubs.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let clubInfoCell = tableView.dequeueReusableCell(withIdentifier: "ClubInfoCell") as? ClubInfoTableViewCell {
      clubInfoCell.club = clubs[indexPath.row]
      return clubInfoCell
    }
    
    return UITableViewCell()
  }
  
  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (action, indexPath) in
      if let clubID = self?.clubs[indexPath.row].clubID {
        SCConnectAPI.REST.Moderators.deleteClubBy(id: clubID, completion: { [weak self] (success) in
          if success {
            let alertController = UIAlertController(title: "Deleted Successfully", message: "The club was permanently deleted.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            DispatchQueue.main.async { [weak self] in
              self?.present(alertController, animated: true, completion: nil)
            }
          }
        })
      }
      self?.clubs.remove(at: indexPath.row)
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
      }
    }
    
    return [deleteAction]
  }
}
