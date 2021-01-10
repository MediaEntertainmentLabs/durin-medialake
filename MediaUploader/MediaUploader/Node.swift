//
//  Node.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

enum NodeType: Int, Codable {
    case container
    case document
    case separator
    case unknown
}

/// - Tag: NodeClass
class Node: NSObject, Codable {
    var type: NodeType = .unknown
    var title: String = ""
    var identifier: String = ""
    var url: URL?
    var is_group_node : Bool = false
    var is_upload_allowed : Bool = false
    @objc dynamic var children = [Node]()
}

extension Node {
    
    /** Called by the tree controller to determine is this node is a leaf node,
     used to determine if the node should have a disclosure triangle.
     */
    @objc dynamic var isLeaf: Bool {
        return type == .document || type == .separator
    }
    
    var isURLNode: Bool {
        return url != nil
    }
    
    var isSpecialGroup: Bool {
        return (!isURLNode && is_group_node)
    }
    
    override class func description() -> String {
        return "Node"
    }
    
    var nodeIcon: NSImage {
        var icon = NSImage()
        if let nodeURL = url {
            // If the node has a URL, use it to obtain its icon.
            icon = nodeURL.icon
        } else {
            // No URL for this node, so determine it's icon generically.
            let osType = isDirectory ? kGenericFolderIcon : kGenericDocumentIcon
            let iconType = NSFileTypeForHFSTypeCode(OSType(osType))
            icon = NSWorkspace.shared.icon(forFileType: iconType!)
        }
        
        return icon
    }
    
    var nodeIconResized: NSImage {
        var icon = NSImage()
        if let nodeURL = url {
            // If the node has a URL, use it to obtain its icon.
            icon = nodeURL.icon
        } else {
            // No URL for this node, so determine it's icon generically.
            let osType = isDirectory ? kGenericFolderIcon : kGenericDocumentIcon
            let iconType = NSFileTypeForHFSTypeCode(OSType(osType))
            icon = NSWorkspace.shared.icon(forFileType: iconType!)
        }
        
        return resize(image: icon, w: 80, h: 80)
    }
    
    func resize(image: NSImage, w: Int, h: Int) -> NSImage {
        let destSize = NSMakeSize(CGFloat(w), CGFloat(h))
        let newImage = NSImage(size: destSize)
        newImage.lockFocus()
        image.draw(in: NSMakeRect(0, 0, destSize.width, destSize.height),
                   from: NSMakeRect(0, 0, image.size.width, image.size.height),
                   operation: NSCompositingOperation.sourceOver,
                   fraction: CGFloat(1))
        newImage.unlockFocus()
        newImage.size = destSize
        return NSImage(data: newImage.tiffRepresentation!)!
    }
    
    var canChange: Bool {
        return false
    }
    
    var canAddTo: Bool {
        return isDirectory && canChange
    }
    
    var isSeparator: Bool {
        return type == .separator
    }
    
    var isDirectory: Bool {
        return type == .container
    }
    
}
