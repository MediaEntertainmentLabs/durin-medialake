//
//  IconSectionHeaderView.swift
//  MediaUploader
//
//  Copyright © 2021 GlobalLogic. All rights reserved.
//

import Cocoa
import AppKit

class IconViewSectionHeader : NSView {
    @IBOutlet weak var sectionTitle: NSTextField!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        if isDarkMode() {
            NSColor(cgColor: NSColor.controlLightHighlightColor.cgColor)?.setFill()
        } else {
            NSColor(calibratedWhite: 0.8 , alpha: 0.8).setFill()
        }
     
        dirtyRect.fill()
    }
}
