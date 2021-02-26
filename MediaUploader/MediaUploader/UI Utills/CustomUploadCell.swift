//
//  CustomUploadCell.swift
//  MediaUploader
//
//  Created by global on 01/02/21.
//  Copyright © 2021 Mykola Gerasymenko. All rights reserved.
//

import Cocoa
import OSLog

protocol FileBrowseDelegate: class {
    func didFileBrowseTapped(_ sender: NSButton)
}

class CustomUploadCell: NSTableCellView {

    @IBOutlet weak var btnBrowse:NSButton!
    @IBOutlet weak var txtFilePath:NSTextField!
    @IBOutlet weak var lblTitle:NSTextField!
    
    weak var delegate: FileBrowseDelegate?

    @IBAction func buttonTapped(_ sender: NSButton) {
        os_log("did file browse tapped", log: .default, type: .debug)
        delegate?.didFileBrowseTapped(sender)
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
}



   


