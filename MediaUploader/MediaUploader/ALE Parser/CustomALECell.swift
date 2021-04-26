//
//  CustomALECell.swift
//  MediaUploader
//
//  Created by global on 13/02/21.
//  Copyright © 2021 Mykola Gerasymenko. All rights reserved.
//

import Cocoa

protocol SourceFileColumnSelectedDelegate: class {
    func didSourceFileColumnSelected(selectedRow:Int , selectedSourceName:NSPopUpButton)
}

protocol ExactContainColumnSelectedDelegate: class {
    func didExactContainColumnSelected(selectedRow:Int , selectedSourceName:NSPopUpButton)
}
class CustomALECell: NSTableCellView,NSTextFieldDelegate {
    @IBOutlet weak var lblPresent:NSTextField!
    @IBOutlet weak var bgView:NSView!
    
    @IBOutlet weak var otherSourceFilesArray: NSPopUpButton!
    @IBOutlet weak var ExactCancelPopUp: NSPopUpButton!
    @IBOutlet weak var lblRemoveLeft: NSTextField!
    @IBOutlet weak var txtRemoveLeft: NSTextField!
    @IBOutlet weak var lblRemoveRight: NSTextField!
    @IBOutlet weak var txtRemoveRight: NSTextField!
    
    weak var sourceFileDelegate: SourceFileColumnSelectedDelegate?
    
    weak var exactContainDelegate: ExactContainColumnSelectedDelegate?

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    @IBAction func popUpSelectionDidChange(_ sender: NSPopUpButton) {
       
        sourceFileDelegate?.didSourceFileColumnSelected(selectedRow: sender.tag, selectedSourceName: sender)
    }
    
    @IBAction func exactContainDidChange(_ sender: NSPopUpButton) {
       
      exactContainDelegate?.didExactContainColumnSelected(selectedRow: sender.tag, selectedSourceName: sender)
    }

    
}
