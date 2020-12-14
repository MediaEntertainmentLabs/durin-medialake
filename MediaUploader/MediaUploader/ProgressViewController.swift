//
//  ProgressView.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class ProgressViewController: NSViewController {

    @IBOutlet weak var progressLabel: NSTextField!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var progressButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchingListOfShows()
    }
    
    @IBAction func buttonClicked(_ sender: NSButton) {
        
        if AppDelegate.lastError == AppDelegate.ErrorStatus.kFailedFetchListShows {
            if let cdsUserId = AppDelegate.retryContext["cdsUserId"] {
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.LoginSuccessfull),
                                                object: nil,
                                                userInfo: ["cdsUserId": cdsUserId])
            }
        } else if AppDelegate.lastError == AppDelegate.ErrorStatus.kFailedFetchShowContent {
            if let showName = AppDelegate.retryContext["showName"],
               let showId = AppDelegate.retryContext["showId"],
               let cdsUserId = AppDelegate.retryContext["cdsUserId"] {
                
                NotificationCenter.default.post(
                    name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
                    object: nil,
                    userInfo: ["showName" : showName, "showId": showId, "cdsUserId" : cdsUserId])
            }
        } else if AppDelegate.lastError == AppDelegate.ErrorStatus.kFailedUploadShowSASToken{
            if let cdsUserId = AppDelegate.retryContext["cdsUserId"],
               let showId = AppDelegate.retryContext["showId"] {
                
                NotificationCenter.default.post(
                    name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
                    object: nil,
                    userInfo: ["cdsUserId" : cdsUserId, "showId": showId])
            }
        }
    }
    
    private func fetchingListOfShows() {
        progressButton.isHidden = true
        progressLabel.stringValue = "Fetching list of shows..."
        progressIndicator.isHidden = false
        progressIndicator.startAnimation(self)
    }
}
