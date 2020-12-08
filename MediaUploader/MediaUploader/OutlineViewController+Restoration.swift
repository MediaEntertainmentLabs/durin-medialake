//
//  OutlineViewController+Restoration.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Foundation

// MARK: -

extension OutlineViewController {
    
    // Restorable key for the currently selected outline node on state restoration.
    private static let savedSelectionKey = "savedSelectionKey"

    /// Key paths for window restoration (including our view controller).
    override class var restorableStateKeyPaths: [String] {
        var keys = super.restorableStateKeyPaths
        keys.append(savedSelectionKey)
        return keys
    }

    /// Encode state. Helps save the restorable state of this view controller.
    override func encodeRestorableState(with coder: NSCoder) {
        let selectedObjects = treeController.selectionIndexPaths
        coder.encode(selectedObjects, forKey: OutlineViewController.savedSelectionKey)
        super.encodeRestorableState(with: coder)
    }

    /// Decode state. Helps restore any previously stored state.
    override func restoreState(with coder: NSCoder) {
        super.restoreState(with: coder)
        // Restore the selected indexPaths.
        if let savedSelectedIndexPaths =
            coder.decodeObject(forKey: OutlineViewController.savedSelectionKey) as? [IndexPath] {
            savedSelection = savedSelectedIndexPaths
            treeController.setSelectionIndexPaths(savedSelection)
        }
    }
    
}
