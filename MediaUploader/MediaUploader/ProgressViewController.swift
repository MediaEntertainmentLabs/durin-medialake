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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        progressLabel.stringValue = "Fetching list of shows..."
        progressIndicator.startAnimation(self)
    }
    
}
