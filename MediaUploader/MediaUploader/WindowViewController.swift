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
    @IBOutlet weak var uploadWindowButton: NSButton!
    @IBOutlet weak var versionLabel: NSTextField!
    
    var window: NSWindow?
   
    override func viewDidAppear() {
        // After a window is displayed, get the handle to the new window.
        window = self.view.window!
        AppDelegate.appDelegate.mainWindowController = window!.windowController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build_number = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                versionLabel.stringValue = "ver.\(ver).\(build_number)"
                print ("------------ ", versionLabel.stringValue)
            }
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let w = self.view.window{
            var frame = w.frame
            frame.size = NSSize(width: 1400, height: 1000)
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

    @IBAction func clearConfig(_ sender: AnyObject) {
        guard let configPath = configURLPath() else { return }
        
        do {
            try FileManager.default.removeItem(atPath: configPath.path)
        } catch _ {
            
        }
    }
    
    @IBAction func showUploadSettings(_ sender: AnyObject) {
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.ShowUploadSettings), object: nil)
    }
    
    @IBAction func showUploadProgressWindow(_ sender: AnyObject) {
        uploadWindowButton.image?.isTemplate = true
        uploadWindowButton.bezelStyle = .inline
        uploadWindowButton.isBordered = false
        uploadWindowButton.bezelColor = NSColor.blue
        uploadWindowButton.highlight(true)
        NotificationCenter.default.post(name: Notification.Name(NotificationNames.ToggleUploadProgressWindow), object: nil)
    }
    
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
        
        static let OnStartUploadShow = "OnStartUploadShow"
        
        static let OnResumeUploadShow = "OnResumeUploadShow"
        
        static let OnPauseUploadShow = "OnPauseUploadShow"
        
        static let OnUploadFailed = "OnStartUploadFailed"
        
        static let IconSelectionChanged = "IconSelectionChanged"
        
        static let NewSASToken = "NewSASToken"
        
        static let RefreshShowContent = "RefreshShowContent"
        
        static let ClearShowContent = "ClearShowContent"
        
        static let ShowProgressViewController = "StartFetchingShowContent"
        
        static let ShowProgressViewControllerOnlyText = "ShowProgressViewControllerOnlyText"
        
        static let ShowOutlineViewController = "ShowOutlineContent"
        
        static let ShowUploadSettings = "ShowUploadSettings"
        
        static let UpdateShowUploadProgress = "UpdateShowUploadProgress"
        
        static let ShowUploadCompleted = "ShowUploadCompleted"
        
        static let ToggleUploadProgressWindow = "ToggleUploadProgressWindow"
        
        static let AddUploadTask = "AddUploadTask"
        
        static let CancelPendingURLTasks = "CancelPendingURLTasks"
        
        static let reloadUploadTableView = "reloadUploadTableView"
        
        static let otpMessage = "otpMessage"
        
        static let generateOTP = "generateOTP"
        
        static let updateFilesToUploadPostResume = "updateFilesToUploadPostResume"
    }
}


