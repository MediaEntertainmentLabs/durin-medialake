//
//  CustomTableCellView.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class CustomTableCellView: NSTableCellView {

    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var progressCompletionStatus: NSTextField!
}
