//
//  SlackMessagesViewController.swift
//  sc-connect-ios-v2-testbed
//
//  Created by Simon Acker on 4/22/17.
//  Copyright © 2017 Simon Acker. All rights reserved.
//

import UIKit
import AVKit // For displaying videos
import AVFoundation // ""
import SlackTextViewController

class SlackMessagesViewController: SLKTextViewController {
  
  // MARK: - SLKTextViewController Required Methods
  
  override var tableView: UITableView {
    get {
      return super.tableView!
    }
  }
  
  override class func tableViewStyle(for decoder: NSCoder) -> UITableViewStyle {
    return .plain
  }
  
  // MARK: - SlackMessagesViewController

  @IBOutlet weak var loadingOldMessagesActivityIndicator: UIActivityIndicatorView!
  var messages = [SkeletonMessage]()
  var typingUsernameList = [String]()
  var loadingOldMessages = false //don't want to load the same messages twice
  var passedTag = Tag()
  
  /// Used to set the navigation title, setup the table view row heights, register two custom table view cells, configure the Slack library, bring the activity indicator to the top, add a gesture recognizer, load old messages, setup listeners for new messages/typing updates, and add notification center observers.
  override func viewDidLoad() {
    super.viewDidLoad()
    navigationItem.title = "\(passedTag.tagName) Messages"
    tableView.rowHeight = UITableViewAutomaticDimension
    tableView.register(UINib(nibName: "SlackMessageTableViewCell", bundle: nil), forCellReuseIdentifier: "SlackMessageCell")
    tableView.register(UINib(nibName: "SlackPhotoMessageTableViewCell", bundle: nil), forCellReuseIdentifier: "SlackPhotoMessageCell")
    configureSLKTextLibrary()
    view.bringSubview(toFront: loadingOldMessagesActivityIndicator)
    view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapOutsideOfTextView)))
    loadLatestMessages()
    listenForNewMessages() // Called here so doesn't create listener everytime the view appears as it would if placed in that part of view lifecycle.
    listenForTypingUpdate()
    NotificationCenter.default.addObserver(tableView, selector: #selector(UITableView.reloadData), name: NSNotification.Name.UIContentSizeCategoryDidChange, object: nil)
  }
  
  /// Used to remove notification center observers before the view controller is deinitialized.
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Used to pass information to the destination view controller.
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == "messagesToMediaUpload" {
      if let mediaUploadVC = segue.destination as? MediaUploadViewController {
        mediaUploadVC.passedTag = passedTag
      }
    } else if segue.identifier == "messagesToTagInfo" {
      if let tagInfoVC = segue.destination as? TagInfoViewController {
        tagInfoVC.passedTag = passedTag
      }
    } else if segue.identifier == "messagesToPhotoDisplay" {
      if let photoDisplayVC = segue.destination as? PhotoDisplayViewController {
        photoDisplayVC.passedPhoto = sender as? UIImage // Passed photo is optional
      }
    }
  }
  
  /// Used to handle a long press gesture on a table view cell.
  func didLongPressCell(_ gesture: UIGestureRecognizer) {
    if gesture.state != .began, let gestureView = gesture.view {
      let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
      alertController.modalPresentationStyle = .popover
      alertController.popoverPresentationController?.sourceView = gestureView.superview
      alertController.popoverPresentationController?.sourceRect = gestureView.frame
      alertController.addAction(UIAlertAction(title: "Flag", style: .destructive, handler: { [weak self] (action) -> Void in
        var messageID: Int?
        if let flaggedMessage = gesture.view as? SlackMessageTableViewCell {
          messageID = flaggedMessage.pureMessage?.messageID
        } else if let flaggedMediaMessage = gesture.view as? SlackPhotoMessageTableViewCell {
          messageID = flaggedMediaMessage.skeletonMessage?.messageID
        }
        if messageID != nil {
          SCConnectAPI.REST.Messages.flagMessageBy(id: messageID!, completion: { [weak self] (success) in
            if success {
              let alertController = UIAlertController(title: "Thank You", message: "Message was successfully flagged. It will be reviewed shortly.", preferredStyle: .alert)
              let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
              alertController.addAction(okAction)
              self?.present(alertController, animated: true, completion: nil)
            }
          })
        }
      }))
      if UserManager.shared.userSignedIn() && UserManager.shared.getUser()!.isModerator {
        alertController.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { [weak self] (action) -> Void in
          let messageID = (gesture.view as? SlackMessageTableViewCell)?.pureMessage?.messageID ?? (gesture.view as? SlackPhotoMessageTableViewCell)?.skeletonMessage?.messageID
          if messageID != nil {
            SCConnectAPI.REST.Moderators.hideMessageBy(id: messageID!, completion: { [weak self] (success) in
              if success {
                let alertController = UIAlertController(title: "Deleted Successfully", message: "The message was permanently deleted.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "Ok", style: .default, handler: nil)
                alertController.addAction(okAction)
                DispatchQueue.main.async { [weak self] in
                  self?.present(alertController, animated: true, completion: nil)
                }
              }
            })
            if self != nil {
              for i in 0..<self!.messages.count {
                if self!.messages[i].messageID == messageID! {
                  self?.messages.remove(at: i)
                  DispatchQueue.main.async { [weak self] in
                    self?.tableView.reloadData()
                  }
                  break
                }
              }
            }
          }
        }))
      }
      alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
      navigationController?.present(alertController, animated: true, completion: nil)
    }
  }
  
  /// Used to handle a tap gesture outside of the text view.
  func didTapOutsideOfTextView(_ gesture: UIGestureRecognizer) {
    dismissKeyboard(true)
  }
  
  /// Used to setup the Slack library.
  func configureSLKTextLibrary() {
    bounces = true
    shakeToClearEnabled = true
    isKeyboardPanningEnabled = true
    shouldScrollToBottomAfterKeyboardShows = false
    isInverted = true
    leftButton.setImage(UIImage(named: "add_media_icon_gray_small"), for: UIControlState())
    leftButton.tintColor = UIColor.gray
    textInputbar.autoHideRightButton = true
    textInputbar.maxCharCount = 256
    textInputbar.counterStyle = .split
    textInputbar.counterPosition = .top
    typingIndicatorView?.interval = 0 // Must be removed
    textView.placeholder = "Your message...";
    tableView.separatorStyle = .none
  }
  
  /// Initial load of messages.
  func loadLatestMessages() {
    SCConnectAPI.REST.Messages.latestMessagesFromTagWith(name: passedTag.tagName) { [weak self, tagName = passedTag.tagName] (messages) in
      if messages != nil {
        if let mostRecentMessage = messages!.first {
          MessagesManager.shared.updateLastReadMessageIndentifierFor(tagName: tagName, to: mostRecentMessage.messageID)
        }
        DispatchQueue.main.async { [weak self] in
          self?.messages.append(contentsOf: messages!)
          self?.tableView.reloadData()
        }
      }
    }
  }
  
  /// Checks for new messages that arrived since the initial load.
  //  - Note: Automatically stops listening when view is deinited bc no completion to be called.
  func listenForNewMessages() {
    SCConnectAPI.Socket.getNewChatMessage { [weak self, tagName = passedTag.tagName] (message) in // Always called when new message sent bc socket stores the closure
      if message != nil && message?.tagName == self?.passedTag.tagName {
        MessagesManager.shared.updateLastReadMessageIndentifierFor(tagName: tagName, to: message!.messageID)
        DispatchQueue.main.async { [weak self] in
          self?.tableView.beginUpdates()
          
          self?.messages.insert(message!, at: 0)
          self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
          
          self?.tableView.endUpdates()
          self?.scrollToBottom()
        }
      }
    }
  }
  
  /// Grabs messages that were posted before the last loaded ones.
  func loadOldMessages() {
    if let lastMessage = messages.last {
      loadingOldMessages = true
      loadingOldMessagesActivityIndicator.startAnimating()
      SCConnectAPI.REST.Messages.messagesFromTagWith(name: passedTag.tagName, beforeMessageWithID: lastMessage.messageID, completion: { [weak self, oldMessagesCount = messages.count] (messages) in
        self?.loadingOldMessages = false
        if messages != nil && messages!.count > 0 {
          DispatchQueue.main.async { [weak self, oldMessagesCount] in
            if let lastContentOffset = self?.tableView.contentOffset {
              self?.tableView.beginUpdates()
              
              var indexPaths = [IndexPath]()
              for row in (oldMessagesCount..<(oldMessagesCount + messages!.count)) {
                indexPaths.append(IndexPath(row: row, section: 0))
              }
              self?.messages.append(contentsOf: messages!)
              self?.tableView.insertRows(at: indexPaths, with: .automatic)
              
              self?.tableView.endUpdates()
              self?.tableView.layer.removeAllAnimations() //maybe not needed
              self?.tableView.setContentOffset(lastContentOffset, animated: false)
              self?.loadingOldMessagesActivityIndicator.stopAnimating()
            }
          }
        } else {
          DispatchQueue.main.async { [weak self] in
            self?.loadingOldMessagesActivityIndicator.stopAnimating()
          }
        }
      })
    }
  }
  
  // Updates the list of users that are currently typing.
  func listenForTypingUpdate() {
    SCConnectAPI.Socket.getTypingUpdate { [weak self, currentTagName = passedTag.tagName] (tagName, typingUsernameList) in
      if self != nil && tagName != nil && typingUsernameList != nil && tagName == currentTagName {
        for username in self!.typingUsernameList {
          if !typingUsernameList!.contains(username) { //only remove if not in new list
            self?.typingIndicatorView?.removeUsername(username)
          }
        }
        for username in typingUsernameList! {
          if !self!.typingUsernameList.contains(username) { //only add if not in old list
            self?.typingIndicatorView?.insertUsername(username)
          }
        }
        self?.typingUsernameList = typingUsernameList!
      }
    }
  }
  
  /// Scrolls to the bottom of the messages if any messages exist.
  func scrollToBottom() {
    if tableView.numberOfSections > 0 && tableView.numberOfRows(inSection: 0) > 0 {
      DispatchQueue.main.async { [weak self] in
        self?.tableView.scrollToRow(at: IndexPath(row: 0, section: 0), at: .bottom, animated: true)
      }
    }
  }
  
  
  // MARK: - SLKTVC Functions
  
  // Notifies the view controller when the left button's action has been triggered, manually.
  override func didPressLeftButton(_ sender: Any!) {
    super.didPressLeftButton(sender)
    dismissKeyboard(true)
    performSegue(withIdentifier: "messagesToMediaUpload", sender: nil)
  }
  
  // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
  override func didPressRightButton(_ sender: Any!) {
    textView.refreshFirstResponder() // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    if UserManager.shared.userSignedIn() {
      if UserManager.shared.isSubscribedTo(tagName: passedTag.tagName) {
        let messageBody = ["pure_message": ["text": textView.text!]] //text should exist if send button is on screen
        if let messageBodyJSONString = Helper.encodeDictionaryIntoJSONString(dictionary: messageBody) {
          SCConnectAPI.Socket.createMessage(messageBody: messageBodyJSONString, tagName: passedTag.tagName)
        }
      } else {
        present(UserManager.shared.notSubscribedAlertController(tagName: passedTag.tagName), animated: true, completion: nil)
      }
    } else {
      present(UserManager.shared.notSignedInAlertController(), animated: true, completion: nil)
    }
    dismissKeyboard(true)
    super.didPressRightButton(sender)
  }
  
  
  // MARK: - UITableViewDelegate
  
  /// Used to load old messages before they will be needed on screen, if possible.
  /// WillEndDragging works better bc has velocity and is called earlier so messages load earlier (less waiting).
  override func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
    if velocity.y > 0.0 && !loadingOldMessages {
      loadOldMessages()
    }
  }
  
  /// Used to start loading the images/video thumbnails once the cell will definitely go on screen. This makes scrolling smoother and saves resources.
  override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
    if let photoMessage = messages[indexPath.row] as? PhotoMessage {
      if photoMessage.photo == nil && photoMessage.loadingPhoto == false {
        photoMessage.loadingPhoto = true
        AWSManager.shared.downloadImageWith(key: photoMessage.photoKey, completion: { [weak self] (image) in //image set once it is downloaded
          photoMessage.photo = image ?? UIImage(named: "error_image")
          photoMessage.loadingPhoto = false
          DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
          }
        })
      }
    } else if let videoMessage = messages[indexPath.row] as? VideoMessage {
      if videoMessage.videoThumbnail == nil && videoMessage.loadingVideoURL == false {
        videoMessage.loadingVideoURL = true
        AWSManager.shared.downloadVideoWith(key: videoMessage.videoKey, completion: { [weak self] (url) in
          videoMessage.loadingVideoURL = false
          videoMessage.videoURL = url
          videoMessage.videoThumbnail = (url != nil ? AWSManager.shared.generateThumbnailOfVideoAt(url: url!) : UIImage(named: "error_image"))
          DispatchQueue.main.async { [weak self] in
            self?.tableView.reloadRows(at: [indexPath], with: .automatic)
          }
        })
      }
    }
  }
  
  /// Used to provide a better estimate of the height of the cell. This prevents jumpiness when scrolling while loading.
  override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
    let message = messages[indexPath.row]
    if message.isKind(of: PureMessage.self) {
      return 60.0
    } else if message.isKind(of: PhotoMessage.self) || message.isKind(of: VideoMessage.self) {
      return 240.0
    }
    
    return 0.0
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
        slackMessageCell.transform = tableView.transform
        if slackMessageCell.gestureRecognizers?.count == nil {
          let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell(_:)))
          slackMessageCell.addGestureRecognizer(longPress)
        }
        slackMessageCell.pureMessage = pureMessage
        return slackMessageCell
      }
    } else if let photoMessage = messages[indexPath.row] as? PhotoMessage {
      if let slackPhotoMessageCell = tableView.dequeueReusableCell(withIdentifier: "SlackPhotoMessageCell") as? SlackPhotoMessageTableViewCell {
        slackPhotoMessageCell.transform = tableView.transform
        if slackPhotoMessageCell.gestureRecognizers?.count == nil {
          let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell(_:)))
          slackPhotoMessageCell.addGestureRecognizer(longPress)
        }
        slackPhotoMessageCell.delegate = self
        slackPhotoMessageCell.skeletonMessage = photoMessage
        slackPhotoMessageCell.display(photo: photoMessage.photo)
        
        return slackPhotoMessageCell
      }
    } else if let videoMessage = messages[indexPath.row] as? VideoMessage {
      if let slackPhotoMessageCell = tableView.dequeueReusableCell(withIdentifier: "SlackPhotoMessageCell") as? SlackPhotoMessageTableViewCell {
        slackPhotoMessageCell.transform = tableView.transform
        if slackPhotoMessageCell.gestureRecognizers?.count == nil {
          let longPress = UILongPressGestureRecognizer(target: self, action: #selector(didLongPressCell(_:)))
          slackPhotoMessageCell.addGestureRecognizer(longPress)
        }
        slackPhotoMessageCell.delegate = self
        slackPhotoMessageCell.skeletonMessage = videoMessage
        slackPhotoMessageCell.display(photo: videoMessage.videoThumbnail)
        
        return slackPhotoMessageCell
      }
    }
    
    return UITableViewCell()
  }
  
  
  // MARK: - UITextViewDelegate
  
  /// Used to prevent users that are not subscribed/signed into a Google account from writing a message. Also shows school property warning if not already shown.
  override func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    if UserManager.shared.userSignedIn() {
      if UserManager.shared.isSubscribedTo(tagName: passedTag.tagName) {
        if UserDefaults.standard.bool(forKey: UserDefaultsConstants.schoolPropertyWarningShownKey) {
          return true
        } else {
          present(UserManager.shared.schoolPropertyWarningAlertController(), animated: true, completion: nil)
          UserDefaults.standard.set(true, forKey: UserDefaultsConstants.schoolPropertyWarningShownKey)
        }
      } else {
        present(UserManager.shared.notSubscribedAlertController(tagName: passedTag.tagName), animated: true, completion: nil)
      }
    } else {
      present(UserManager.shared.notSignedInAlertController(), animated: true, completion: nil)
    }
    
    return false
  }
  
  /// Used to send update that the user is typing.
  override func textViewDidBeginEditing(_ textView: UITextView) {
    SCConnectAPI.Socket.sendStartTypingMessageOnTagWith(name: passedTag.tagName)
    scrollToBottom()
  }
  
  /// Used to send update that the user stopped typing.
  override func textViewDidEndEditing(_ textView: UITextView) {
    SCConnectAPI.Socket.sendStopTypingMessageOnTagWith(name: passedTag.tagName)
  }
}

extension SlackMessagesViewController: SlackPhotoMessageTableViewDelegate {
  
  /// Used to show video or photo inspector when user taps on the photo/thumbnail.
  func didTapPhotoInCellOf(message: SkeletonMessage) {
    if let photoMessage = message as? PhotoMessage, photoMessage.photo != nil { // won't load until photo is loaded
      performSegue(withIdentifier: "messagesToPhotoDisplay", sender: photoMessage.photo)
    } else if let videoMessage = message as? VideoMessage, videoMessage.videoURL != nil { // won't load video until url is loaded
      let player = AVPlayer(url: videoMessage.videoURL!)
      let playerController = AVPlayerViewController()
      playerController.player = player
      playerController.view.frame = view.frame
      present(playerController, animated: true, completion: {
        playerController.player?.play()
      })
    }
  }
}
