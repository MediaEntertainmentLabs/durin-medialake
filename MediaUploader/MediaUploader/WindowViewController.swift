//
//  WindowViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class WindowViewController: NSViewController {

    @IBOutlet weak var logoutButton: NSButton!
    @IBOutlet weak var username: NSTextField!
    

    // reference to a window
    var window: NSWindow?
   
    override func viewDidAppear() {
        // After a window is displayed, get the handle to the new window.
        window = self.view.window!
           

        AppDelegate.appDelegate.mainWindowController = window!.windowController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let w = self.view.window{
            var frame = w.frame
            frame.size = NSSize(width: 900, height: 600)
            w.setFrame(frame, display: true, animate: true)
            
        }
        
        NotificationCenter.default.addObserver(
             self,
             selector: #selector(updateUserName(_:)),
             name: Notification.Name(WindowViewController.NotificationNames.updateUserNameLabel),
             object: nil)
    }
    

    @objc func updateUserName(_ notification: NSNotification) {

        if let azureUserName = notification.userInfo?["azureUserName"] as? String {
            self.username.stringValue = azureUserName
        }
    }

    @IBAction func logoutAction(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.logoutItem), object: nil)
        window?.performClose(nil) // nil because I'm not return a message
    }

    #if ENABLE_UPLOAD_WINDOW
    @IBAction func showUploadProgressWindow(_ sender: AnyObject) {
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.updateUserNameLabel), object: nil)
    }
    #endif
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.updateUserNameLabel),
            object: nil)
    }
    
    
    struct NotificationNames {
        static let logoutItem = "LogoutNotification"
        
        static let showUploadWindow = "ShowUploadWindowNotification"
        
        static let updateUserNameLabel = "UpdateUserNameLabel"
        
        static let LoginSuccessfull = "OnLoginSuccessfull"
        
        static let DismissUploadSettingsDialog = "DismissUploadSettingsDialog"
        
        static let UploadShow = "UploadMetadata"
        
        static let IconSelectionChanged = "IconSelectionChanged"
        
        static let NewSASToken = "NewSASToken"
        
        static let ShowProgressViewController = "StartFetchingShowContent"
        
        static let ShowProgressViewControllerOnlyText = "ShowProgressViewControllerOnlyText"
        
        static let ShowOutlineViewController = "ShowOutlineContent"
    }
}


