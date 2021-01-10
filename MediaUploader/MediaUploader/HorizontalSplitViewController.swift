//
//  HorizontalSplitViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class HorizontalSplitViewController: NSSplitViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        splitViewItems[1].isCollapsed = true
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onToggleUploadWindow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.ToggleUploadProgressWindow),
            object: nil)
    }
    
    @objc func onToggleUploadWindow(_ sender: Any) {
        splitViewItems[1].isCollapsed = !splitViewItems[1].isCollapsed
        print ("splitViewItems[1].isCollapsed:", splitViewItems[1].isCollapsed)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.ToggleUploadProgressWindow),
            object: nil)
    }
}
