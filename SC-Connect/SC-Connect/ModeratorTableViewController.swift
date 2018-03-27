//
//  ModeratorTableViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 6/7/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class ModeratorTableViewController: UITableViewController {
  
  /// Called when the moderator requests that the leaderboard be cleared.
  @IBAction func didTapClearLeaderboardScores(_ sender: UIButton) {
    let alertController = UIAlertController(title: "Warning", message: "Are you are sure you can to clear all leaderboard scores?", preferredStyle: .alert)
    alertController.addAction(UIAlertAction(title: "Clear", style: .destructive) { (action) in
      SCConnectAPI.REST.Moderators.clearLeaderboardScores(completion: { [weak self] (success) in
        if success {
          let alertController = UIAlertController(title: "Success", message: "Leaderboard was cleared.", preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
          self?.present(alertController, animated: true, completion: nil)
        } else {
          let alertController = UIAlertController(title: "Error", message: "Leaderboard was not cleared.", preferredStyle: .alert)
          alertController.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
          self?.present(alertController, animated: true, completion: nil)
        }
      })
    })
    alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
    present(alertController, animated: true, completion: nil)
  }
}
