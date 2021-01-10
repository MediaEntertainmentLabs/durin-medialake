//
//  OutlineView.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class OutlineView: NSOutlineView {
    
    var contextualRect = NSRect()
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.deselectAll(nil)
        if !contextualRect.isEmpty {
            // Draw the highlight.
            let rectPath = NSBezierPath(rect: contextualRect)
            let fillColor = NSColor.keyboardFocusIndicatorColor
            fillColor.set()
            rectPath.stroke()
        }
    }
    
    override func didCloseMenu(_ menu: NSMenu, with event: NSEvent?) {
        super.didCloseMenu(menu, with: event)
        
        if !contextualRect.isEmpty {
            // Clear the highlight when the menu closes.
            contextualRect = NSRect()
            setNeedsDisplay(bounds)
        }
    }
    
}
