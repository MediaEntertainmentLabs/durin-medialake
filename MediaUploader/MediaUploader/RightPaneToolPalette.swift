//
//  RightPaneToolPalette.swift
//  MediaUploader
//
//  Copyright © 2021 GlobalLogic. All rights reserved.
//

import Cocoa


class RightPaneToolPalette: NSViewController {

    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
 
    
    @IBAction func onRefreshShowContent(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.RefreshShowContent), object: nil)
    }
}
