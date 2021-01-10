//
//  OutlineViewController+Expansion.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

extension OutlineViewController {
    
    private func nodeFromIdentifier(anObject: Any, nodes: [NSTreeNode]!) -> NSTreeNode? {
        var treeNode: NSTreeNode?
        for node in nodes {
            if let testNode = node.representedObject as? Node {
                let idCheck = anObject as? String
                if idCheck == testNode.identifier {
                    treeNode = node
                    break
                }
                if node.children != nil {
                    if let nodeCheck = nodeFromIdentifier(anObject: anObject, nodes: node.children) {
                        treeNode = nodeCheck
                        break
                    }
                }
            }
        }
        return treeNode
    }
    
    private func nodeFromIdentifier(anObject: Any) -> NSTreeNode? {
        return nodeFromIdentifier(anObject: anObject, nodes: treeController.arrangedObjects.children)
    }

    /** When the outline view is restoring the saved expanded items, this method is called for each
     	expanded item, to translate the archived object to an outline view item.
     */
/// - Tag: RestoreExpansion
    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        let node = nodeFromIdentifier(anObject: object)  // Incoming object is the identifier.
        return node
    }
    
    /** When the outline view is saving the expanded items, this method is called for each expanded
     	item, to translate the outline view item to an archived object.
     */
/// - Tag: EncodeExpansion
    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        let node = OutlineViewController.node(from: item!)
        return node?.identifier // Outgoing object is the identifier.
    }
}
