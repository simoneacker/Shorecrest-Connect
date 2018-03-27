//
//  SportsTableViewCell.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/7/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

/// Custom cell used to display information about a `ScheduledSportsGame` or a `SportsGameResult`.
class SportsTableViewCell: UITableViewCell {
  
  /// Shows the date and time of the game.
  @IBOutlet weak var dateLabel: UILabel!
  
  /// Displays the home team's logo.
  @IBOutlet weak var homeIconImageView: UIImageView!
  
  /// Displays the opoonent's logo.
  @IBOutlet weak var opponentIconImageView: UIImageView!
  
  /// Shows the name of the home team.
  @IBOutlet weak var homeNameLabel: UILabel!
  
  /// Shows the name of the opponent.
  @IBOutlet weak var opponentNameLabel: UILabel!
  
  /// Shows the location name if scheduled game or the home team's score if a result.
  @IBOutlet weak var locationNameOrHomeScoreLabel: UILabel!
  
  /// Shows the opponent's score if a result.
  @IBOutlet weak var opponentScoreLabel: UILabel!
  
  /*
      Holds the `ScheduledSportsGame` model shown in the cell. Passed in by the owner of the cell. Also, updates the cell ui when it is changed.
   
      - Note: Property is used here instead of a function so the full event info is available if the cell is used as a sender for a segue.
   */
  public var scheduledGame: ScheduledSportsGame? {
    didSet {
      if scheduledGame != nil { // Prevent infinite looping of setting properties to nil
        gameResult = nil // Clear result so scheduled game is definitely shown
        updateUI()
      }
    }
  }
  
  /*
      Holds the `SportsGameResult` model shown in the cell. Passed in by the owner of the cell. Also, updates the cell ui when it is changed.
   
      - Note: Property is used here instead of a function so the full event info is available if the cell is used as a sender for a segue.
   */
  public var gameResult: SportsGameResult? {
    didSet {
      if gameResult != nil { // Prevent infinite looping of setting properties to nil
        scheduledGame = nil // Clear scheduled game so result is definitely shown
        updateUI()
      }
    }
  }
  
  /// Updates the display to reflect the current scheduled game or game result that was passed to the cell.
  private func updateUI() {
    homeNameLabel.text = "Shorecrest"
    homeIconImageView.image = UIImage(named: "Shorecrest")
    
    if let scheduledGame = scheduledGame {
      dateLabel.text = "\(Helper.dayStringFrom(date: scheduledGame.date)) at \(Helper.timeStringFrom(date: scheduledGame.date))"
      opponentNameLabel.text = scheduledGame.opponentName
      opponentIconImageView.image = UIImage(named: scheduledGame.opponentName)
      locationNameOrHomeScoreLabel.text = scheduledGame.locationName
      opponentScoreLabel.text = nil
    } else if let gameResult = gameResult {
      if let opponentImage = UIImage(named: gameResult.opponentName) {
        opponentIconImageView.image = opponentImage
      } else {
        opponentIconImageView.image = UIImage(named: "default_image_icon_small")
      }
      if gameResult.homeScore == -1 || gameResult.opponentScore == -1 { // Scores couldn't be parsed
        dateLabel.text = Helper.dayStringFrom(date: gameResult.date)
        opponentNameLabel.text = gameResult.opponentName
        locationNameOrHomeScoreLabel.text = nil
        opponentScoreLabel.text = nil
      } else {
        dateLabel.text = Helper.dayStringFrom(date: gameResult.date)
        opponentNameLabel.text = gameResult.opponentName
        locationNameOrHomeScoreLabel.text = "\(gameResult.homeScore)"
        opponentScoreLabel.text = "\(gameResult.opponentScore)"
      }
    }
  }
}
