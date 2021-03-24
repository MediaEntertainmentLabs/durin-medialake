//
//  UploadStatusTableCellView.swift
//  MediaUploader
//
//  Copyright © 2021 GlobalLogic. All rights reserved.
//

import Cocoa

protocol PauseResumeDelegate: class {
    func didPauseResumeTapped(_ sender: NSButton)
}

class UploadStatusTableCellView: NSTableCellView {

    weak var pauseResumeDelegate: PauseResumeDelegate?
    
    @IBOutlet weak var btnPauseResume: NSButton!
    @IBOutlet weak var lblStatus: NSTextField!
    @IBOutlet weak var imgStatus: NSImageView!
    
    @IBAction func btnPauseResumeClicked(_ sender: NSButton) {
        pauseResumeDelegate?.didPauseResumeTapped(sender)
    }
}
