//
//  OutlineViewController+Delegate.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

extension OutlineViewController: NSOutlineViewDelegate,NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {

      if let node = item as? Node {
        return node.children.count
      }
      
      return contents.count
    }
    
    // Is the outline view item a group node? (not a folder but a group with Hide/Show buttons).
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        let node = OutlineViewController.node(from: item)
        return node!.isSpecialGroup
    }
    
    // Should we select the outline view item? (no selection for special groupings or separators).
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        
        
        if let node = OutlineViewController.node(from: item) {
            return !node.isSpecialGroup && !node.isSeparator
        } else {
            return false
        }
    }
    
    // What should be the row height of an outline view item?
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        var rowHeight = outlineView.rowHeight
        
        guard let node = OutlineViewController.node(from: item) else { return rowHeight }

        if node.isSeparator {
            // Separator rows have a smaller height.
            rowHeight = 8.0
        }
        return rowHeight
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?
        //print("NSOutlineViewDelegate::outlineView  viewFor Thread.isMainThread ", Thread.isMainThread)
        guard let node = OutlineViewController.node(from: item) else { return view }
        
        if self.outlineView(outlineView, isGroupItem: item) {
            // The row is a group node, return NSTableCellView as a special group row.
            view = outlineView.makeView(
                withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "GroupCell"), owner: self) as? NSTableCellView
            view?.textField?.stringValue = node.title.uppercased()
        } else {
            if tableColumn?.identifier == NSUserInterfaceItemIdentifier("ShownameColumn") {
                
                // The row is a regular outline node, return NSTableCellView with an image and title
                view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "MainCell"), owner: self) as? NSTableCellView
                view?.textField?.stringValue = node.title
                view?.imageView?.image = node.nodeIcon
                
                // Folder titles are editable only if they do not have a file URL,
                // (We don't want users to rename file system-based nodes).
                view?.textField?.isEditable = node.canChange
            }
        }

        return view
    }
    
    // An outline row view was just inserted.
    func outlineView(_ outlineView: NSOutlineView, didAdd rowView: NSTableRowView, forRow row: Int) {
        
        // Are we adding a newly inserted row that needs a new name?
        if rowToAdd != -1 {
            // Force-edit the newly added row's name.
            if let view = outlineView.view(atColumn: 0, row: rowToAdd, makeIfNecessary: false) {
                if let cellView = view as? NSTableCellView {
                    view.window?.makeFirstResponder(cellView.textField)
                }
                rowToAdd = -1
            }
        }
    }
    
}
