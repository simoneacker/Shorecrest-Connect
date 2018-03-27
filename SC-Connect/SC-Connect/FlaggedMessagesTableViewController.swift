//
//  FlaggedMessagesTableViewController.swift
//  sc-connect-ios-v2-cookies+sockets
//
//  Created by Simon Acker on 5/11/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit

class FlaggedMessagesTableViewController: UITableViewController {
  
  /// Holds the flagged messages once they are downloaded.
  var messages = [SkeletonMessage]()
  
  /// Used to setup table view and download flagged messages.
  override func viewDidLoad() {
    super.viewDidLoad()
    tableView.estimatedRowHeight = 250 //overestimate
    tableView.rowHeight = UITableViewAutomaticDimension
    refreshControl = UIRefreshControl()
    refreshControl?.addTarget(self, action: #selector(refreshFlaggedMessages), for: .valueChanged)
    refreshFlaggedMessages()
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
  
  /// Used to download and store all flagged messages data.
  func refreshFlaggedMessages() {
    SCConnectAPI.REST.Messages.flaggedMessages { [weak self] (messages) in
      if messages != nil {
        self?.messages.append(contentsOf: messages!)
      }
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
        self?.refreshControl?.endRefreshing()
      }
    }
  }
  
  // MARK: - UITableViewDelegate
  
  /// Used to start loading the images/video thumbnails once the cell will definitely go on screen. This makes scrolling smoother and saves resources.
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if let photoMessage = messages[indexPath.row] as? PhotoMessage {
      if photoMessage.photo == nil && photoMessage.loadingPhoto == false {
        photoMessage.loadingPhoto = true
        AWSManager.shared.downloadImageWith(key: photoMessage.photoKey, completion: { [weak self] (image) in //image set once it is downloaded
          photoMessage.photo = image //store downloaded image
          photoMessage.loadingPhoto = false
          DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [indexPath], with: .none)
          }
        })
      }
    } else if let videoMessage = messages[indexPath.row] as? VideoMessage {
      if videoMessage.videoThumbnail == nil && videoMessage.loadingVideoURL == false {
        videoMessage.loadingVideoURL = true
        AWSManager.shared.downloadVideoWith(key: videoMessage.videoKey, completion: { [weak self] (url) in
          videoMessage.loadingVideoURL = false
          if url != nil {
            videoMessage.videoURL = url
            videoMessage.videoThumbnail = AWSManager.shared.generateThumbnailOfVideoAt(url: url!)
          } else {
            videoMessage.videoURL = nil
            videoMessage.videoThumbnail = nil
          }
          DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [indexPath], with: .none)
          }
        })
      }
    }
  }
  
  
  // MARK: - UITableViewDataSource
  
  override func numberOfSections(in tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return messages.count
  }
  
  override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if let pureMessage = messages[indexPath.row] as? PureMessage {
      if let slackMessageCell = tableView.dequeueReusableCell(withIdentifier: "SlackMessageCell") as? SlackMessageTableViewCell {
        slackMessageCell.pureMessage = pureMessage
        
        return slackMessageCell
      }
    } else if let photoMessage = messages[indexPath.row] as? PhotoMessage {
      if let slackPhotoMessageCell = tableView.dequeueReusableCell(withIdentifier: "SlackPhotoMessageCell") as? SlackPhotoMessageTableViewCell {
        slackPhotoMessageCell.skeletonMessage = photoMessage
        slackPhotoMessageCell.display(photo: photoMessage.photo)
        
        return slackPhotoMessageCell
      }
    } else if let videoMessage = messages[indexPath.row] as? VideoMessage {
      if let slackPhotoMessageCell = tableView.dequeueReusableCell(withIdentifier: "SlackPhotoMessageCell") as? SlackPhotoMessageTableViewCell {
        slackPhotoMessageCell.skeletonMessage = videoMessage
        slackPhotoMessageCell.display(photo: videoMessage.videoThumbnail)
        
        return slackPhotoMessageCell
      }
    }
    
    return UITableViewCell()
  }
  
  override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
    let unflagAction = UITableViewRowAction(style: .normal, title: "Unflag") { [weak self] (action, indexPath) in
      if let messageID = self?.messages[indexPath.row].messageID {
        SCConnectAPI.REST.Messages.unflagMessageBy(id: messageID, completion: { [weak self] (success) in
          if success {
            let alertController = UIAlertController(title: "Unflagged Successfully", message: "The message was unflagged. It will no longer appear under flagged messages.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            DispatchQueue.main.async { [weak self] in
              self?.present(alertController, animated: true, completion: nil)
            }
          }
        })
      }
      self?.messages.remove(at: indexPath.row)
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
      }
    }
    unflagAction.backgroundColor = .blue
    
    let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete") { [weak self] (action, indexPath) in
      if let messageID = self?.messages[indexPath.row].messageID {
        SCConnectAPI.REST.Moderators.hideMessageBy(id: messageID, completion: { [weak self] (success) in
          if success {
            let alertController = UIAlertController(title: "Deleted Successfully", message: "The message was permanently deleted.", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
            alertController.addAction(okAction)
            DispatchQueue.main.async { [weak self] in
              self?.present(alertController, animated: true, completion: nil)
            }
          }
        })
      }
      self?.messages.remove(at: indexPath.row)
      DispatchQueue.main.async { [weak self] in
        self?.tableView.reloadData()
      }
    }
    
    return [deleteAction, unflagAction] // Shown in opposite order on screen.
  }
}
