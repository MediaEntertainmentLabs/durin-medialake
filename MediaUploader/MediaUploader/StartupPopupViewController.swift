//
//  StartupPopupViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa


class StartupPopupViewController : NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var fetchAPIURLsTestField: NSTextField!
    @IBOutlet weak var applyButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        applyButton.isEnabled = false
        
        fetchAPIURLsTestField.delegate = self
    }

    @IBAction func applyClicked(_ sender: Any) {
        
        if fetchAPIURLsTestField.stringValue.isEmpty {
            return
        }
        writeConfig(item: ["apiURL":fetchAPIURLsTestField.stringValue])
        self.dismiss(self)
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.LoginSuccessfull),
                                        object: nil)
    }
    
    func controlTextDidChange(_ notification: Notification) {
        if let textField = notification.object as? NSTextField {
            if textField.stringValue.isEmpty {
                return
            }
            applyButton.isEnabled = true
        }
    }
}

