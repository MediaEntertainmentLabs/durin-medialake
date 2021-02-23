//
//  UploadStatusTableCellView.swift
//  MediaUploader
//
//  Created by global on 23/02/21.
//  Copyright © 2021 Mykola Gerasymenko. All rights reserved.
//

import Cocoa

protocol PauseResumeDelegate: class {
    func didPauseResumeTapped(_ sender: NSButton)
}

class UploadStatusTableCellView: NSTableCellView {

    
    weak var pauseResumeDelegate: PauseResumeDelegate?
    
    @IBAction func btnPauseResumeClicked(_ sender: NSButton) {
        pauseResumeDelegate?.didPauseResumeTapped(sender)
    }
    @IBOutlet weak var btnPauseResume: NSButton!
    @IBOutlet weak var lblStatus: NSTextField!
    @IBOutlet weak var imgStatus: NSImageView!
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}
